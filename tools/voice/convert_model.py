"""Kokoro's int8 model with its slow convolutions made fast: python3 convert_model.py <in> <out>

ONNX Runtime runs the int8 model's ConvInteger steps on one CPU core with a slow kernel, and they
take about three quarters of Kokoro's time. Here each one becomes DequantizeLinear on its int8
weights followed by an ordinary float Conv with the layer's original float bias, which ONNX
Runtime runs fast on every core. The weights stay int8 in the file, so it stays about 88 MB; the
activations are no longer rounded to 8 bits, so the sound is as good or better. Measured on an M4
Mac: 1.5x faster, with spectrograms matching the original's (correlation 0.98).

Expects the pattern ONNX Runtime's dynamic quantization writes for a Conv:
    DynamicQuantizeLinear(x) -> ConvInteger -> [Add(bias quantized at run time)] -> Cast -> Mul(scale)
"""
import collections
import sys

from onnx_wire import (GRAPH_INITIALIZER, GRAPH_NODE, GRAPH_OUTPUT, GRAPH_VALUE_INFO, MODEL_GRAPH,
                       VALUE_INFO_NAME, Node, first, make_node, parse, serialize, tensor_name)


def convert(model_bytes):
    model = parse(model_bytes)
    graph = parse(first(model, MODEL_GRAPH))
    nodes = [Node(value) for field, wire, value in graph if field == GRAPH_NODE]
    initializers = {tensor_name(value) for field, wire, value in graph if field == GRAPH_INITIALIZER}
    producer = {output: node for node in nodes for output in node.outputs}
    consumers = collections.defaultdict(list)
    for node in nodes:
        for name in node.inputs:
            consumers[name].append(node)

    def only_consumer(name, op_type):
        found = consumers[name]
        assert len(found) == 1 and found[0].op_type == op_type, (name, op_type)
        return found[0]

    replaced, removed = {}, set()
    for conv in [node for node in nodes if node.op_type == "ConvInteger"]:
        x_quantized, weights, x_zero_point, weights_zero_point = conv.inputs
        assert weights in initializers and weights_zero_point in initializers, conv.name
        quantize = producer[x_quantized]
        assert quantize.op_type == "DynamicQuantizeLinear", conv.name
        after = consumers[conv.outputs[0]]
        assert len(after) == 1, conv.name
        bias = None
        if after[0].op_type == "Add":
            add = after[0]
            reshape = producer[next(name for name in add.inputs if name != conv.outputs[0])]
            to_int = producer[reshape.inputs[0]]
            floor = producer[to_int.inputs[0]]
            divide = producer[floor.inputs[0]]
            assert (reshape.op_type, to_int.op_type, floor.op_type, divide.op_type) == \
                ("Reshape", "Cast", "Floor", "Div"), conv.name
            bias = divide.inputs[0]
            assert bias in initializers, conv.name
            cast = only_consumer(add.outputs[0], "Cast")
            removed.add(id(add))
        else:
            cast = only_consumer(conv.outputs[0], "Cast")
        rescale = only_consumer(cast.outputs[0], "Mul")
        scales = producer[next(name for name in rescale.inputs if name != cast.outputs[0])]
        assert scales.op_type == "Mul" and scales.inputs[0] == quantize.outputs[1], conv.name
        weights_scale = scales.inputs[1]
        assert weights_scale in initializers, conv.name

        float_weights = weights + "_dequantized"
        replaced[id(conv)] = [
            make_node("DequantizeLinear", [weights, weights_scale, weights_zero_point], [float_weights],
                      conv.name + "_weights_dequantized"),
            make_node("Conv", [quantize.inputs[0], float_weights] + ([bias] if bias else []),
                      [rescale.outputs[0]], conv.name.removesuffix("_quant") + "_float", conv.attributes),
        ]
        removed |= {id(conv), id(cast), id(rescale)}

    # New nodes go where their ConvInteger was, which keeps the order topological. Then drop
    # whatever nothing reads any more (the activation and bias quantizers, the scale products).
    kept = []
    for node in nodes:
        if id(node) in replaced:
            kept += replaced[id(node)]
        elif id(node) not in removed:
            kept.append(node)
    graph_outputs = {first(parse(value), VALUE_INFO_NAME).decode()
                     for field, wire, value in graph if field == GRAPH_OUTPUT}
    while True:
        read = {name for node in kept for name in node.inputs} | graph_outputs
        still_used = [node for node in kept if any(output in read for output in node.outputs if output)]
        if len(still_used) == len(kept):
            break
        kept = still_used
    read = {name for node in kept for name in node.inputs} | graph_outputs
    made = {output for node in kept for output in node.outputs}

    new_graph, nodes_written = [], False
    for field, wire, value in graph:
        if field == GRAPH_NODE:
            if not nodes_written:
                new_graph += [(GRAPH_NODE, 2, node.serialize()) for node in kept]
                nodes_written = True
        elif field == GRAPH_INITIALIZER and tensor_name(value) not in read:
            continue
        elif field == GRAPH_VALUE_INFO and first(parse(value), VALUE_INFO_NAME).decode() not in made:
            continue
        else:
            new_graph.append((field, wire, value))
    new_model = [(field, wire, serialize(new_graph) if field == MODEL_GRAPH else value)
                 for field, wire, value in model]
    left = collections.Counter(node.op_type for node in kept)
    assert left["ConvInteger"] == 0
    print(f"{len(replaced)} ConvInteger steps now float Conv; {len(nodes)} -> {len(kept)} steps")
    return serialize(new_model)


if __name__ == "__main__":
    source, target = sys.argv[1], sys.argv[2]
    with open(source, "rb") as file:
        converted = convert(file.read())
    with open(target, "wb") as file:
        file.write(converted)

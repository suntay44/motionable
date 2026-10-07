"""Just enough of the protobuf wire format to edit an ONNX graph, so the model can be converted
with the Python that comes with macOS: no onnx or numpy package needed."""


def read_varint(data, i):
    shift = result = 0
    while True:
        byte = data[i]
        i += 1
        result |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return result, i
        shift += 7


def write_varint(number):
    out = bytearray()
    while True:
        byte = number & 0x7F
        number >>= 7
        if number:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def parse(data):
    """A message's fields in order, as (field number, wire type, value). Varints are ints; every
    other value stays bytes, so fields this file doesn't know are written back unchanged."""
    fields, i, end = [], 0, len(data)
    while i < end:
        key, i = read_varint(data, i)
        field, wire = key >> 3, key & 7
        if wire == 0:
            value, i = read_varint(data, i)
        elif wire == 1:
            value, i = data[i:i + 8], i + 8
        elif wire == 2:
            length, i = read_varint(data, i)
            value, i = data[i:i + length], i + length
        elif wire == 5:
            value, i = data[i:i + 4], i + 4
        else:
            raise ValueError(f"unsupported wire type {wire}")
        fields.append((field, wire, value))
    return fields


def serialize(fields):
    out = bytearray()
    for field, wire, value in fields:
        out += write_varint((field << 3) | wire)
        if wire == 0:
            out += write_varint(value)
        elif wire == 2:
            out += write_varint(len(value))
            out += value
        else:
            out += value
    return bytes(out)


def strings(fields, number):
    return [value.decode() for field, wire, value in fields if field == number]


def first(fields, number, default=None):
    for field, wire, value in fields:
        if field == number:
            return value
    return default


# Field numbers from onnx.proto.
MODEL_GRAPH = 7
GRAPH_NODE, GRAPH_INITIALIZER, GRAPH_OUTPUT, GRAPH_VALUE_INFO = 1, 5, 12, 13
NODE_INPUT, NODE_OUTPUT, NODE_NAME, NODE_OP_TYPE, NODE_ATTRIBUTE, NODE_DOMAIN = 1, 2, 3, 4, 5, 7
TENSOR_NAME = 8
VALUE_INFO_NAME = 1


class Node:
    def __init__(self, raw):
        self.fields = parse(raw)
        self.inputs = strings(self.fields, NODE_INPUT)
        self.outputs = strings(self.fields, NODE_OUTPUT)
        name = first(self.fields, NODE_NAME)
        self.name = name.decode() if name else ""
        self.op_type = first(self.fields, NODE_OP_TYPE).decode()
        self.attributes = [value for field, wire, value in self.fields if field == NODE_ATTRIBUTE]

    def serialize(self):
        return serialize(self.fields)


def make_node(op_type, inputs, outputs, name, attributes=()):
    fields = [(NODE_INPUT, 2, text.encode()) for text in inputs]
    fields += [(NODE_OUTPUT, 2, text.encode()) for text in outputs]
    fields += [(NODE_NAME, 2, name.encode()), (NODE_OP_TYPE, 2, op_type.encode())]
    fields += [(NODE_ATTRIBUTE, 2, attribute) for attribute in attributes]
    return Node(serialize(fields))


def tensor_name(raw):
    return first(parse(raw), TENSOR_NAME).decode()

// Optional offline Kokoro worker. ONNX Runtime headers/library are installed by voice.py setup.
#include <onnxruntime_cxx_api.h>
#include <fstream>
#include <iostream>
#include <vector>
#include <cmath>

int main(int argc, char **argv) {
    try {
        if (argc != 5) throw std::runtime_error("usage: infer <model> <voice> <token-lines> <output-prefix>");
        std::ifstream voice(argv[2], std::ios::binary | std::ios::ate);
        if (!voice || voice.tellg() != 510 * 256 * sizeof(float)) throw std::runtime_error("Invalid voice file");
        std::vector<float> styles(510 * 256);
        voice.seekg(0); voice.read(reinterpret_cast<char *>(styles.data()), styles.size() * sizeof(float));
        Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "motionable-voice");
        Ort::SessionOptions options;
        options.SetIntraOpNumThreads(4);
        options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
        Ort::Session session(env, argv[1], options);
        auto memory = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
        std::ifstream input(argv[3]);
        if (!input) throw std::runtime_error("Missing tokens");
        int count, index = 0;
        while (input >> count) {
            if (count < 1 || count > 510) throw std::runtime_error("Phrase must have 1–510 tokens; split at a sentence boundary");
            std::vector<int64_t> tokens(count + 2, 0);
            for (int i = 1; i <= count; ++i) if (!(input >> tokens[i])) throw std::runtime_error("Incomplete tokens");
            int64_t tokenShape[] = {1, count + 2}, styleShape[] = {1, 256}, speedShape[] = {1};
            float speed = 1.0f;
            std::vector<Ort::Value> tensors;
            tensors.push_back(Ort::Value::CreateTensor<int64_t>(memory, tokens.data(), tokens.size(), tokenShape, 2));
            tensors.push_back(Ort::Value::CreateTensor<float>(memory, styles.data() + (count - 1) * 256, 256, styleShape, 2));
            tensors.push_back(Ort::Value::CreateTensor<float>(memory, &speed, 1, speedShape, 1));
            const char *names[] = {"tokens", "style", "speed"}, *outputs[] = {"audio"};
            auto result = session.Run(Ort::RunOptions{nullptr}, names, tensors.data(), 3, outputs, 1);
            auto length = result[0].GetTensorTypeAndShapeInfo().GetElementCount();
            auto samples = result[0].GetTensorData<float>();
            if (!length || length > 24000 * 120) throw std::runtime_error("Invalid generated duration");
            for (size_t i = 0; i < length; ++i) if (!std::isfinite(samples[i])) throw std::runtime_error("Non-finite audio");
            std::ofstream out(std::string(argv[4]) + std::to_string(index++) + ".f32", std::ios::binary);
            out.write(reinterpret_cast<const char *>(samples), length * sizeof(float));
            if (!out) throw std::runtime_error("Cannot write generated audio");
        }
        if (!index) throw std::runtime_error("No phrases");
    } catch (const std::exception &e) { std::cerr << e.what() << '\n'; return 1; }
}

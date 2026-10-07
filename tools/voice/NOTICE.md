# Optional local voice dependencies

The pronunciation and token helpers and asset preparation scripts are adapted from
Christian Patrick Suntay's Watch-Health-Tracker Luna implementation (2026-10-06).
`KokoroPhonemizer.swift` ports rules from hexgrad's Misaki `en.py` (Apache-2.0).
No health data, UI code or recordings from that application are distributed here.

- Kokoro-82M v1.0 weights and voice assets: hexgrad, Apache-2.0.
  https://huggingface.co/hexgrad/Kokoro-82M
- Misaki word lists/rules: hexgrad, Apache-2.0; pinned word-list revision
  `fba1236595f2d2bf21d414ba6e57d25256afada3`.
  https://github.com/hexgrad/misaki
- kokoro-onnx model distribution: thewh1teagle, MIT code, Apache-2.0 weights.
  https://github.com/thewh1teagle/kokoro-onnx
- ONNX Runtime 1.24.2: Microsoft, MIT. The optional runtime archive retains its
  LICENSE and ThirdPartyNotices files in the shared installation.
  https://github.com/microsoft/onnxruntime

License texts accompany these helpers in `licenses/`. Model weights and the native
runtime are optional downloads, not committed to the plugin or copied into films.
The Swift port deliberately omits Misaki's neural fallback and espeak-ng. Unknown
words are reported for a reviewed spoken spelling; there is no system-voice fallback.

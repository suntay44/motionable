import Foundation

@main struct Phonemes {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            fputs("usage: phonemes <lexicon.tsv> <script.json>\n", stderr); exit(2)
        }
        struct Phrase: Decodable { let id: String; let text: String; let spoken: String? }
        struct Script: Decodable { let phrases: [Phrase] }
        struct Output: Encodable { let id: String; let tokens: [Int64]; let unknown: [String] }
        let lexicon = KokoroLexicon(data: try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let engine = KokoroPhonemizer(lexicon: lexicon)
        let script = try JSONDecoder().decode(Script.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
        let output = script.phrases.map { phrase -> Output in
            let spoken = (phrase.spoken ?? phrase.text).replacingOccurrences(of: "’", with: "'")
            let result = engine.phonemes(for: spoken)
            return Output(id: phrase.id, tokens: KokoroTokens.ids(result.phonemes), unknown: result.unknown)
        }
        FileHandle.standardOutput.write(try JSONEncoder().encode(output))
    }
}

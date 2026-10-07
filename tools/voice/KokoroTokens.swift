import Foundation

/// Kokoro 1.0's symbols as the numbers the model takes, and how a sentence's sounds are cut to
/// fit it (at most 510 symbols a run).
public enum KokoroTokens {
    /// The most symbols the model takes in one run, and the number of style rows a voice has.
    public static let maxTokens = 510

    /// Kokoro 1.0's 114 symbols with their numbers, from its config (kokoro-onnx's DEFAULT_VOCAB).
    static let vocabulary: [Unicode.Scalar: Int64] = {
        let symbols = Array(";:,.!?\u{2014}\u{2026}\"()\u{201C}\u{201D} \u{0303}\u{02A3}\u{02A5}\u{02A6}\u{02A8}\u{1D5D}\u{AB67}AIOQSTWY\u{1D4A}abcdefhijklmnopqrstuvwxyz\u{0251}\u{0250}\u{0252}\u{00E6}\u{03B2}\u{0254}\u{0255}\u{00E7}\u{0256}\u{00F0}\u{02A4}\u{0259}\u{025A}\u{025B}\u{025C}\u{025F}\u{0261}\u{0265}\u{0268}\u{026A}\u{029D}\u{026F}\u{0270}\u{014B}\u{0273}\u{0272}\u{0274}\u{00F8}\u{0278}\u{03B8}\u{0153}\u{0279}\u{027E}\u{027B}\u{0281}\u{027D}\u{0282}\u{0283}\u{0288}\u{02A7}\u{028A}\u{028B}\u{028C}\u{0263}\u{0264}\u{03C7}\u{028E}\u{0292}\u{0294}\u{02C8}\u{02CC}\u{02D0}\u{02B0}\u{02B2}\u{2193}\u{2192}\u{2197}\u{2198}\u{1D7B}".unicodeScalars)
        let numbers: [Int64] = [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
                                31, 33, 35, 36, 39, 41, 42, 43, 44, 45, 46, 47, 48, 50, 51, 52, 53, 54, 55, 56, 57,
                                58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 75, 76, 77, 78, 80, 81,
                                82, 83, 85, 86, 87, 90, 92, 99, 101, 102, 103, 110, 111, 112, 113, 114, 115, 116,
                                118, 119, 120, 123, 125, 126, 128, 129, 130, 131, 132, 133, 135, 136, 138, 139, 140,
                                142, 143, 147, 148, 156, 157, 158, 162, 164, 169, 171, 172, 173, 177]
        precondition(symbols.count == numbers.count)
        return Dictionary(uniqueKeysWithValues: zip(symbols, numbers))
    }()

    /// The model's input for `phonemes`: their numbers, with symbols it doesn't know left out.
    public static func ids(_ phonemes: String) -> [Int64] {
        phonemes.unicodeScalars.compactMap { vocabulary[$0] }
    }

    /// The model takes the numbers with a 0 at each end.
    public static func padded(_ ids: [Int64]) -> [Int64] {
        [0] + ids + [0]
    }

    /// Which of a voice's 510 style rows goes with this many symbols: row n - 1 for n symbols.
    public static func styleRow(count: Int) -> Int {
        min(max(count, 1), maxTokens) - 1
    }

    /// One sentence's sounds in pieces of at most `target` symbols where it can, so the first
    /// sound is ready sooner: cut after a comma, semicolon, colon or dash, never inside a word, and
    /// never over `limit`.
    public static func pieces(_ phonemes: String, target: Int, limit: Int = maxTokens) -> [String] {
        let phonemes = phonemes.trimmingCharacters(in: .whitespaces)
        guard !phonemes.isEmpty else { return [] }
        if ids(phonemes).count <= min(target, limit) { return [phonemes] }
        var clauses: [String] = []
        var current = ""
        for word in phonemes.split(separator: " ") {
            current += current.isEmpty ? String(word) : " " + word
            if let last = word.last, ",;:—".contains(last) {
                clauses.append(current)
                current = ""
            }
        }
        if !current.isEmpty { clauses.append(current) }

        var pieces: [String] = []
        current = ""
        for clause in clauses {
            let joined = current.isEmpty ? clause : current + " " + clause
            if current.isEmpty || ids(joined).count <= target {
                current = joined
            } else {
                pieces.append(current)
                current = clause
            }
        }
        if !current.isEmpty { pieces.append(current) }
        return pieces.flatMap { piece in ids(piece).count <= limit ? [piece] : byWords(piece, limit: limit) }
    }

    /// A piece too long even for one run, cut between words.
    static func byWords(_ phonemes: String, limit: Int) -> [String] {
        var pieces: [String] = []
        var current = ""
        for word in phonemes.split(separator: " ") {
            let joined = current.isEmpty ? String(word) : current + " " + word
            if ids(joined).count <= limit {
                current = joined
            } else {
                if !current.isEmpty { pieces.append(current) }
                // A single "word" longer than a run can't happen with real words; cut it anyway.
                var word = Substring(word)
                while ids(String(word)).count > limit {
                    pieces.append(String(word.prefix(limit)))
                    word = word.dropFirst(limit)
                }
                current = String(word)
            }
        }
        if !current.isEmpty { pieces.append(current) }
        return pieces
    }
}

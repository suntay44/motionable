import Foundation
import NaturalLanguage

// Adapted from Watch-Health-Tracker's Luna implementation. Misaki's American English
// lexicon/rules (hexgrad, Apache-2.0); see NOTICE.md. No neural or espeak fallback.
// Unknown words must be resolved before synthesis; this helper never chooses another voice.

/// Misaki's word lists, read from lexicon.tsv (made by tools/luna/make_lexicon.py): about 180,000
/// lines of "word <tab> g|s <tab> sounds", sorted by word, where sounds may be
/// "DEFAULT=...;NOUN=...". Words are found by binary search in the file's own bytes, so loading
/// it takes milliseconds and no memory beyond the file.
public struct KokoroLexicon: Sendable {
    /// One word's sounds: always the same, or by word class ("DEFAULT", "NOUN", "VERB", "ADJ",
    /// "ADV", "DT", "VBD"..., and "None" at the end of a phrase). An empty value means "spell it".
    enum Sounds: Sendable, Equatable {
        case always(String)
        case byClass([String: String])
    }

    private let bytes: [UInt8]
    /// Where each line starts, in the order of its word's bytes (Python sorted the file by code
    /// point, which is the same order); gold ("g") before silver ("s") for the same word.
    private let lines: [Int]

    public var count: Int { lines.count }

    /// Lines starting with "#" are comments. Lines out of order (in tests) are sorted here.
    public init(tsv: String) {
        self.init(bytes: Array(tsv.utf8))
    }

    public init(data: Data) {
        self.init(bytes: [UInt8](data))
    }

    private init(bytes: [UInt8]) {
        var lines: [Int] = []
        lines.reserveCapacity(bytes.count / 24)
        bytes.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            var start = 0
            while start < buffer.count {
                let rest = buffer.count - start
                let end = memchr(base + start, 0x0A, rest).map { UnsafePointer($0.assumingMemoryBound(to: UInt8.self)) - base }
                    ?? buffer.count
                if end > start, buffer[start] != UInt8(ascii: "#") { lines.append(start) }
                start = end + 1
            }
        }
        self.bytes = bytes
        let inOrder = zip(lines, lines.dropFirst()).allSatisfy { Self.order(bytes, $0, $1) <= 0 }
        self.lines = inOrder ? lines : lines.sorted { Self.order(bytes, $0, $1) < 0 }
    }

    /// Optional vocabulary additions in Misaki symbols. Keep product-specific spellings in the script.
    static let ownWords: [String: String] = [:]

    func gold(_ word: String) -> Sounds? {
        if let own = Self.ownWords[word] ?? (word == Self.capitalized(word) ? Self.ownWords[word.lowercased()] : nil) {
            return .always(own)
        }
        return grown(word, mark: UInt8(ascii: "g"))
    }
    func silver(_ word: String) -> Sounds? { grown(word, mark: UInt8(ascii: "s")) }

    /// Misaki's `grow_dictionary`: a lowercase word also answers for its capitalized form ("bunny"
    /// for "Bunny"), and a capitalized one for its lowercase form ("Luna" for "luna"). Words of
    /// one letter don't grow.
    private func grown(_ word: String, mark: UInt8) -> Sounds? {
        if let sounds = entry(word, mark: mark) { return sounds }
        guard word.count >= 2 else { return nil }
        let lower = word.lowercased()
        if word == lower {
            let capital = Self.capitalized(word)
            return capital != word ? entry(capital, mark: mark) : nil
        }
        return word == Self.capitalized(lower) ? entry(lower, mark: mark) : nil
    }

    /// Python's `str.capitalize`: the first letter in capitals, the rest lowercase.
    static func capitalized(_ word: String) -> String {
        word.prefix(1).uppercased() + word.dropFirst().lowercased()
    }

    private func entry(_ word: String, mark: UInt8) -> Sounds? {
        let key = Array(word.utf8)
        var low = 0, high = lines.count
        while low < high {
            let middle = (low + high) / 2
            if compare(lines[middle], key) < 0 { low = middle + 1 } else { high = middle }
        }
        var index = low
        while index < lines.count, compare(lines[index], key) == 0 {
            let start = lines[index]
            let markAt = start + key.count + 1
            if markAt + 2 < bytes.count, bytes[markAt] == mark, bytes[markAt + 1] == UInt8(ascii: "\t") {
                var end = markAt + 2
                while end < bytes.count, bytes[end] != 0x0A { end += 1 }
                return Self.sounds(String(decoding: bytes[(markAt + 2)..<end], as: UTF8.self))
            }
            index += 1
        }
        return nil
    }

    /// How the word on the line at `start` sorts against `key`.
    private func compare(_ start: Int, _ key: [UInt8]) -> Int {
        var index = start, keyIndex = 0
        while true {
            let atEnd = index >= bytes.count || bytes[index] == UInt8(ascii: "\t") || bytes[index] == 0x0A
            if atEnd { return keyIndex == key.count ? 0 : -1 }
            if keyIndex == key.count { return 1 }
            if bytes[index] != key[keyIndex] { return bytes[index] < key[keyIndex] ? -1 : 1 }
            index += 1
            keyIndex += 1
        }
    }

    /// How two lines sort: by word, then by mark.
    private static func order(_ bytes: [UInt8], _ a: Int, _ b: Int) -> Int {
        var i = a, j = b
        while true {
            let aEnd = i >= bytes.count || bytes[i] == 0x0A, bEnd = j >= bytes.count || bytes[j] == 0x0A
            if aEnd || bEnd { return aEnd == bEnd ? 0 : (aEnd ? -1 : 1) }
            if bytes[i] != bytes[j] {
                // The tab after a word sorts before any letter, so "heart" comes before "hearts".
                return bytes[i] < bytes[j] ? -1 : 1
            }
            i += 1
            j += 1
        }
    }

    private static func sounds(_ field: String) -> Sounds? {
        guard field.contains("=") else { return field.isEmpty ? nil : .always(field) }
        var byClass: [String: String] = [:]
        for pair in field.split(separator: ";") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 { byClass[String(parts[0])] = String(parts[1]) }
        }
        return byClass["DEFAULT"] == nil ? nil : .byClass(byClass)
    }
}

/// A word's class in its sentence, from Apple's NaturalLanguage tagger, for the few words said
/// differently as a noun or a verb ("close", "wind", "record") and for "a", "I", "in" and "used".
public enum WordClass: Sendable, Equatable {
    case noun, verb, adjective, adverb, determiner, pronoun, preposition, particle, other

    init(_ tag: NLTag) {
        self = switch tag {
        case .noun: .noun
        case .verb: .verb
        case .adjective: .adjective
        case .adverb: .adverb
        case .determiner: .determiner
        case .pronoun: .pronoun
        case .preposition: .preposition
        case .particle: .particle
        default: .other
        }
    }

    /// The key a word list entry uses for this class.
    var lexiconKey: String? {
        switch self {
        case .noun: "NOUN"
        case .verb: "VERB"
        case .adjective: "ADJ"
        case .adverb: "ADV"
        case .determiner: "DT"
        default: nil
        }
    }

    /// Without the tagger (in tests): the usual class of the words whose sound depends on it.
    static func usual(for word: String) -> WordClass? {
        switch word.lowercased() {
        case "a", "an", "the": .determiner
        case "i": .pronoun
        case "in": .preposition
        case "to": .particle
        default: nil
        }
    }
}

public struct KokoroPhonemizer: Sendable {
    public let lexicon: KokoroLexicon

    public init(lexicon: KokoroLexicon) {
        self.lexicon = lexicon
    }

    public struct Result: Sendable, Equatable {
        /// Kokoro's symbols for the text, words separated by spaces, pause marks kept.
        public var phonemes: String
        /// Words with no known sound, left out of `phonemes`. Synthesis must stop when any remain.
        public var unknown: [String]

        public init(phonemes: String, unknown: [String]) {
            self.phonemes = phonemes
            self.unknown = unknown
        }
    }

    /// The sounds of `text` (numbers/symbols already written as spoken words). `tagsWords` uses Apple's
    /// tagger to tell nouns from verbs; tests turn it off to stay the same on every system.
    public func phonemes(for text: String, tagsWords: Bool = true) -> Result {
        var tokens = Self.tokens(in: text, tagsWords: tagsWords)
        if tagsWords { markCommands(&tokens) }
        var sounds = [String](repeating: "", count: tokens.count)
        var unknown: [String] = []
        // Right to left, like Misaki: a word's sound can depend on the next one.
        var context = Context()
        for index in tokens.indices.reversed() {
            let token = tokens[index]
            if token.isWord {
                if let found = word(token.text, token.wordClass, context) {
                    sounds[index] = found
                } else {
                    unknown.append(token.text)
                }
            } else {
                sounds[index] = token.text
            }
            context = context.next(after: sounds[index], token: token)
        }
        var phonemes = ""
        for (token, sound) in zip(tokens, sounds) {
            phonemes += sound
            if token.spaceAfter && !sound.isEmpty { phonemes += " " }
        }
        // Kokoro 1.0 was trained with Misaki's flap "ɾ" written "T", and the glottal stop "ʔ" as "t".
        phonemes = phonemes.replacing("ɾ", with: "T").replacing("ʔ", with: "t")
        phonemes = phonemes.replacing(/[ ]{2,}/) { _ in " " }.trimmingCharacters(in: .whitespaces)
        return Result(phonemes: phonemes, unknown: unknown.reversed())
    }

    /// Apple's tagger often misses a command at the start of a sentence: "Wind down early",
    /// "Close your eyes" and "Record how you feel" come back as a noun or an adverb. A first word
    /// said differently as a verb, followed by "the", "your", "how" or "down", is the verb.
    func markCommands(_ tokens: inout [Token]) {
        var startsSentence = true
        for index in tokens.indices {
            let token = tokens[index]
            guard token.isWord else {
                startsSentence = startsSentence || [".", "!", "?", "…"].contains(token.text)
                continue
            }
            defer { startsSentence = false }
            guard startsSentence, token.wordClass != .verb, index + 1 < tokens.count, tokens[index + 1].isWord,
                  [.determiner, .pronoun, .particle].contains(tokens[index + 1].wordClass),
                  case .byClass(let sounds)? = lexicon.gold(token.text.lowercased()), sounds["VERB"] != nil
            else { continue }
            tokens[index].wordClass = .verb
        }
    }

    // MARK: - Words and pause marks

    struct Token {
        var text: String
        var isWord: Bool
        var spaceAfter = false
        var wordClass: WordClass?
    }

    static let leadingApostropheWords: Set<String> = ["'cause", "'em", "'tis", "'twas"]

    /// Whether a word like "'em" starts here: the whole word, so a quote around "'empty'" or
    /// "'causeway'" is just a quote.
    static func startsApostropheWord(_ text: String, at index: String.Index) -> Bool {
        let rest = text[index...].prefix(8).lowercased()
        return leadingApostropheWords.contains { word in
            guard rest.hasPrefix(word) else { return false }
            return rest.dropFirst(word.count).first.map { !$0.isLetter } ?? true
        }
    }

    /// Words (letters, with apostrophes and hyphens inside) and Kokoro's pause marks, in order.
    static func tokens(in text: String, tagsWords: Bool) -> [Token] {
        var classes: [String.Index: WordClass] = [:]
        if tagsWords {
            let tagger = NLTagger(tagSchemes: [.lexicalClass])
            tagger.string = text
            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass,
                                 options: [.omitWhitespace, .omitPunctuation]) { tag, range in
                if let tag { classes[range.lowerBound] = WordClass(tag) }
                return true
            }
        }
        var tokens: [Token] = []
        var index = text.startIndex
        func isWordCharacter(_ i: String.Index) -> Bool {
            i < text.endIndex && (text[i].isLetter || text[i].isNumber)
        }
        while index < text.endIndex {
            let character = text[index]
            if character.isWhitespace {
                if !tokens.isEmpty { tokens[tokens.count - 1].spaceAfter = true }
                index = text.index(after: index)
                continue
            }
            let startsWord = character.isLetter || character.isNumber
                || (character == "'" && startsApostropheWord(text, at: index))
            if startsWord {
                let start = index
                index = text.index(after: index)
                while index < text.endIndex {
                    let next = text.index(after: index)
                    if isWordCharacter(index) {
                        index = next
                    } else if text[index] == "'" || text[index] == "-", isWordCharacter(next) {
                        index = next
                    } else if text[index] == "'", text[text.index(before: index)] == "s" {
                        // The plural possessive: "nights'".
                        index = next
                        break
                    } else {
                        break
                    }
                }
                let word = String(text[start..<index])
                let wordClass = tagsWords ? classes[start] : WordClass.usual(for: word)
                tokens.append(Token(text: word, isWord: true, wordClass: wordClass))
            } else {
                if Self.pauseMarks.contains(character) {
                    tokens.append(Token(text: String(character), isWord: false))
                }
                index = text.index(after: index)
            }
        }
        return tokens
    }

    /// Kokoro's punctuation symbols, which it reads as pauses and tone.
    static let pauseMarks: Set<Character> = [";", ":", ",", ".", "!", "?", "—", "…", "\"", "“", "”", "(", ")"]

    /// Misaki's `TokenContext`: what follows the word being looked at.
    struct Context {
        /// Whether the next word starts with a vowel sound; nil before a pause mark or at the end.
        var futureVowel: Bool?
        /// Whether the next word is "to".
        var futureTo = false

        func next(after sound: String, token: Token) -> Context {
            var vowel = futureVowel
            for scalar in sound.unicodeScalars {
                if Sound.nonQuotePauses.contains(scalar) { vowel = nil; break }
                if Sound.vowels.contains(scalar) { vowel = true; break }
                if Sound.consonants.contains(scalar) { vowel = false; break }
            }
            let isTo = token.text == "to" || token.text == "To"
                || (token.text == "TO" && [.particle, .preposition].contains(token.wordClass))
            return Context(futureVowel: vowel, futureTo: isTo)
        }
    }

    // MARK: - One word

    /// A word's sounds, or nil when no list or rule knows it.
    func word(_ text: String, _ wordClass: WordClass?, _ context: Context) -> String? {
        if let sounds = misakiWord(text, wordClass, context) { return sounds }
        if text.contains("-"), let sounds = compound(text, wordClass, context) { return sounds }
        // The reference implementation’s rule for a short word no list knows: say its letters.
        if text.count <= 4, text.allSatisfy(Self.isLexiconLetter) { return spell(text) }
        return nil
    }

    /// Misaki's `Lexicon.__call__`: capitals add a little stress, then `get_word`.
    func misakiWord(_ text: String, _ wordClass: WordClass?, _ context: Context) -> String? {
        let stress: Double? = text == text.lowercased() ? nil : (text == text.uppercased() ? 2 : 0.5)
        return getWord(text, wordClass, stress, context)
    }

    func getWord(_ text: String, _ wordClass: WordClass?, _ stress: Double?, _ context: Context) -> String? {
        if let special = specialCase(text, wordClass, stress, context) { return special }
        var word = text
        let lower = word.lowercased()
        let withoutApostrophes = word.replacing("'", with: "")
        if word.count > 1, !withoutApostrophes.isEmpty, withoutApostrophes.allSatisfy(\.isLetter), word != lower,
           lexicon.gold(word) == nil, lexicon.silver(word) == nil,
           word == word.uppercased() || word.dropFirst() == word.dropFirst().lowercased(),
           lexicon.gold(lower) != nil || lexicon.silver(lower) != nil
            || stemS(lower, wordClass, stress, context) != nil
            || stemED(lower, wordClass, stress, context) != nil
            || stemING(lower, wordClass, stress, context) != nil {
            word = lower
        }
        if isKnown(word) { return lookup(word, wordClass, stress, context) }
        if word.hasSuffix("s'"), isKnown(String(word.dropLast(2)) + "'s") {
            return lookup(String(word.dropLast(2)) + "'s", wordClass, stress, context)
        }
        if word.hasSuffix("'"), isKnown(String(word.dropLast())) {
            return lookup(String(word.dropLast()), wordClass, stress, context)
        }
        return stemS(word, wordClass, stress, context)
            ?? stemED(word, wordClass, stress, context)
            ?? stemING(word, wordClass, stress ?? 0.5, context)
    }

    /// Misaki's `get_special_case`, for the words a list can't get right alone.
    func specialCase(_ word: String, _ wordClass: WordClass?, _ stress: Double?, _ context: Context) -> String? {
        switch word {
        case "a", "A":
            return wordClass == .determiner ? "ɐ" : "ˈA"
        case "AM":
            // Reference behavior: "AM" only comes from clock times, so it's always the letters.
            return spell(word)
        case "am", "Am":
            if wordClass == .noun { return spell(word) }
            if context.futureVowel == nil || word != "am" || (stress ?? 0) > 0 { return goldSounds("am") }
            return "ɐm"
        case "an", "An", "AN":
            return word == "AN" && wordClass == .noun ? spell(word) : "ɐn"
        // A `where` here would only guard the last word of a list, so the class is checked inside.
        case "I":
            return wordClass == .pronoun ? "ˌI" : nil
        case "by", "By", "BY":
            return wordClass == .adverb ? "bˈI" : nil
        case "to", "To":
            return toSound(context)
        case "TO":
            return [.particle, .preposition].contains(wordClass) ? toSound(context) : nil
        case "in", "In", "IN":
            return (context.futureVowel == nil || wordClass != .preposition ? "ˈ" : "") + "ɪn"
        case "the", "The":
            return context.futureVowel == true ? "ði" : "ðə"
        case "THE":
            return wordClass == .determiner ? (context.futureVowel == true ? "ði" : "ðə") : nil
        case "used", "Used", "USED":
            guard case .byClass(let sounds) = lexicon.gold("used") else { return nil }
            return [.verb, .adjective].contains(wordClass) && context.futureTo ? sounds["VBD"] : sounds["DEFAULT"]
        default:
            return nil
        }
    }

    private func toSound(_ context: Context) -> String? {
        switch context.futureVowel {
        case nil: goldSounds("to")
        case false?: "tə"
        case true?: "tʊ"
        }
    }

    private func goldSounds(_ word: String) -> String? {
        if case .always(let sounds) = lexicon.gold(word) { return sounds }
        return nil
    }

    /// Misaki's `is_known`.
    func isKnown(_ word: String) -> Bool {
        if lexicon.gold(word) != nil || lexicon.silver(word) != nil { return true }
        guard !word.isEmpty, word.allSatisfy(Self.isLexiconLetter) else { return false }
        if word.count == 1 { return true }
        if word == word.uppercased(), lexicon.gold(word.lowercased()) != nil { return true }
        return word.dropFirst() == word.dropFirst().uppercased()
    }

    static func isLexiconLetter(_ character: Character) -> Bool {
        character.isASCII && character.isLetter
    }

    /// Misaki's `lookup`: the list's sounds for the word's class, or its letters.
    func lookup(_ word: String, _ wordClass: WordClass?, _ stress: Double?, _ context: Context) -> String? {
        var word = word
        if word == word.uppercased(), lexicon.gold(word) == nil {
            word = word.lowercased()
        }
        var sounds: String?
        switch lexicon.gold(word) ?? lexicon.silver(word) {
        case .always(let always)?:
            sounds = always
        case .byClass(let byClass)?:
            let key: String
            if context.futureVowel == nil, byClass["None"] != nil {
                key = "None"
            } else {
                key = wordClass?.lexiconKey ?? "DEFAULT"
            }
            let value = byClass[key] ?? byClass["DEFAULT"]!
            sounds = value.isEmpty ? nil : value
        case nil:
            sounds = nil
        }
        guard let sounds else { return spell(word) }
        return Sound.applyStress(sounds, stress)
    }

    /// Misaki's `get_NNP`: a word said as its letters, "HRV" as "aitch ar vee", the last letter
    /// stressed most.
    func spell(_ word: String) -> String? {
        var letters = ""
        for character in word where character.isLetter {
            guard case .always(let sounds) = lexicon.gold(character.uppercased()) else { return nil }
            letters += sounds
        }
        guard !letters.isEmpty else { return nil }
        let softened = Sound.applyStress(letters, 0)
        guard let last = softened.lastIndex(of: Sound.secondary) else { return softened }
        return softened.replacingCharacters(in: last...last, with: String(Sound.primary))
    }

    // MARK: - Endings

    /// "-s": "nights", "minutes", "that's", "watches".
    func stemS(_ word: String, _ wordClass: WordClass?, _ stress: Double?, _ context: Context) -> String? {
        guard word.count >= 3, word.hasSuffix("s") else { return nil }
        let stem: String
        if !word.hasSuffix("ss"), isKnown(String(word.dropLast())) {
            stem = String(word.dropLast())
        } else if word.hasSuffix("'s") || (word.count > 4 && word.hasSuffix("es") && !word.hasSuffix("ies")),
                  isKnown(String(word.dropLast(2))) {
            stem = String(word.dropLast(2))
        } else if word.count > 4, word.hasSuffix("ies"), isKnown(String(word.dropLast(3)) + "y") {
            stem = String(word.dropLast(3)) + "y"
        } else {
            return nil
        }
        return lookup(stem, wordClass, stress, context).flatMap(Sound.addS)
    }

    /// "-ed": "recovered", "missed".
    func stemED(_ word: String, _ wordClass: WordClass?, _ stress: Double?, _ context: Context) -> String? {
        guard word.count >= 4, word.hasSuffix("d") else { return nil }
        let stem: String
        if !word.hasSuffix("dd"), isKnown(String(word.dropLast())) {
            stem = String(word.dropLast())
        } else if word.count > 4, word.hasSuffix("ed"), !word.hasSuffix("eed"), isKnown(String(word.dropLast(2))) {
            stem = String(word.dropLast(2))
        } else {
            return nil
        }
        return lookup(stem, wordClass, stress, context).flatMap(Sound.addED)
    }

    /// "-ing": "getting", "adding".
    func stemING(_ word: String, _ wordClass: WordClass?, _ stress: Double?, _ context: Context) -> String? {
        guard word.count >= 5, word.hasSuffix("ing") else { return nil }
        let base = String(word.dropLast(3))
        let stem: String
        if word.count > 5, isKnown(base) {
            stem = base
        } else if isKnown(base + "e") {
            stem = base + "e"
        } else if word.count > 5, word.contains(/([bcdgklmnprstvxz])\1ing$|cking$/), isKnown(String(word.dropLast(4))) {
            stem = String(word.dropLast(4))
        } else {
            return nil
        }
        return lookup(stem, wordClass, stress, context).flatMap(Sound.addING)
    }

    // MARK: - Hyphens

    /// "well-rested": each part on its own, then Misaki's `resolve_tokens` evens out the stress.
    func compound(_ word: String, _ wordClass: WordClass?, _ context: Context) -> String? {
        let parts = word.split(separator: "-").map(String.init)
        guard parts.count >= 2 else { return nil }
        var sounds = [String](repeating: "", count: parts.count)
        var context = context
        for index in parts.indices.reversed() {
            guard let found = self.word(parts[index], wordClass, context) else { return nil }
            sounds[index] = found
            context = context.next(after: found, token: Token(text: parts[index], isWord: true))
        }
        let stressed = sounds.indices.filter { !sounds[$0].isEmpty }.map { index in
            (primary: sounds[index].contains(Sound.primary), weight: Sound.weight(sounds[index]), index: index)
        }
        if stressed.count == 2, parts[stressed[0].index].count == 1 {
            sounds[stressed[1].index] = Sound.applyStress(sounds[stressed[1].index], -0.5)
        } else if stressed.count >= 2, stressed.filter(\.primary).count > (stressed.count + 1) / 2 {
            let lightest = stressed.sorted { a, b in
                (a.primary ? 1 : 0, a.weight, a.index) < (b.primary ? 1 : 0, b.weight, b.index)
            }
            for item in lightest.prefix(stressed.count / 2) {
                sounds[item.index] = Sound.applyStress(sounds[item.index], -0.5)
            }
        }
        return sounds.joined()
    }
}

/// Misaki's sound helpers: stress marks, and the endings' own sounds.
enum Sound {
    static let primary: Character = "ˈ"
    static let secondary: Character = "ˌ"
    static let vowels = Set("AIOQWYaiuæɑɒɔəɛɜɪʊʌᵻ".unicodeScalars)
    static let consonants = Set("bdfhjklmnpstvwzðŋɡɹɾʃʒʤʧθ".unicodeScalars)
    static let nonQuotePauses = Set(";:,.!?—…".unicodeScalars)
    static let diphthongs = Set("AIOQWYʤʧ".unicodeScalars)
    /// Vowels before a "t" that becomes a flap in American English ("getting").
    static let flapping = Set("AIOWYiuæɑəɛɪɹʊʌ".unicodeScalars)

    static func weight(_ sounds: String) -> Int {
        sounds.unicodeScalars.reduce(0) { $0 + (diphthongs.contains($1) ? 2 : 1) }
    }

    /// Misaki's `apply_stress`.
    static func applyStress(_ sounds: String, _ stress: Double?) -> String {
        guard let stress else { return sounds }
        let hasPrimary = sounds.contains(primary), hasSecondary = sounds.contains(secondary)
        let hasVowel = sounds.unicodeScalars.contains(where: vowels.contains)
        if stress < -1 {
            return sounds.replacing(String(primary), with: "").replacing(String(secondary), with: "")
        } else if stress == -1 || ((stress == 0 || stress == -0.5) && hasPrimary) {
            return sounds.replacing(String(secondary), with: "").replacing(String(primary), with: String(secondary))
        } else if [0, 0.5, 1].contains(stress), !hasPrimary, !hasSecondary {
            return hasVowel ? restress(String(secondary) + sounds) : sounds
        } else if stress >= 1, !hasPrimary, hasSecondary {
            return sounds.replacing(String(secondary), with: String(primary))
        } else if stress > 1, !hasPrimary, !hasSecondary {
            return hasVowel ? restress(String(primary) + sounds) : sounds
        }
        return sounds
    }

    /// Misaki's `restress`: each stress mark moves to just before the next vowel.
    static func restress(_ sounds: String) -> String {
        let scalars = Array(sounds.unicodeScalars)
        let placed = scalars.enumerated().map { index, scalar -> (position: Double, scalar: Unicode.Scalar) in
            guard scalar == "ˈ" || scalar == "ˌ",
                  let vowel = scalars[index...].firstIndex(where: vowels.contains) else {
                return (Double(index), scalar)
            }
            return (Double(vowel) - 0.5, scalar)
        }
        let sorted = placed.sorted { ($0.position, $0.scalar.value) < ($1.position, $1.scalar.value) }
        var result = String.UnicodeScalarView()
        result.append(contentsOf: sorted.map(\.scalar))
        return String(result)
    }

    /// "-s" after a stem's sounds: "s" after p, t, k, f, th; "ᵻz" after hissing sounds; else "z".
    static func addS(_ stem: String) -> String? {
        guard let last = stem.unicodeScalars.last else { return nil }
        if "ptkfθ".unicodeScalars.contains(last) { return stem + "s" }
        if "szʃʒʧʤ".unicodeScalars.contains(last) { return stem + "ᵻz" }
        return stem + "z"
    }

    /// "-ed": "t" after voiceless sounds, "ᵻd" after d, and the American flap after a vowel and t.
    static func addED(_ stem: String) -> String? {
        let scalars = Array(stem.unicodeScalars)
        guard let last = scalars.last else { return nil }
        if "pkfθʃsʧ".unicodeScalars.contains(last) { return stem + "t" }
        if last == "d" { return stem + "ᵻd" }
        if last != "t" { return stem + "d" }
        if scalars.count < 2 { return stem + "ɪd" }
        if flapping.contains(scalars[scalars.count - 2]) {
            return String(String.UnicodeScalarView(scalars.dropLast())) + "ɾᵻd"
        }
        return stem + "ᵻd"
    }

    /// "-ing", with the American flap after a vowel and t.
    static func addING(_ stem: String) -> String? {
        let scalars = Array(stem.unicodeScalars)
        guard !scalars.isEmpty else { return nil }
        if scalars.count > 1, scalars.last == "t", flapping.contains(scalars[scalars.count - 2]) {
            return String(String.UnicodeScalarView(scalars.dropLast())) + "ɾɪŋ"
        }
        return stem + "ɪŋ"
    }
}

import Foundation

struct PlateCheckResult {
    var cleaned: String
    var problems: [String]
    var isValidFormat: Bool { problems.isEmpty }
}

enum PlateRules {
    /// Normalizes input and checks it against a state's basic format rules.
    static func check(_ raw: String, state: StateInfo, maxLength: Int? = nil) -> PlateCheckResult {
        let limit = maxLength ?? state.maxLength
        let cleaned = raw.uppercased().trimmingCharacters(in: .whitespaces)
        var problems: [String] = []

        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ")
        if cleaned.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            problems.append("Only letters, numbers and spaces are allowed.")
        }
        if !state.allowsSpace && cleaned.contains(" ") {
            problems.append("\(state.name) doesn't allow spaces.")
        }

        let length = cleaned.count
        if length < state.minLength {
            problems.append("Too short. Minimum is \(state.minLength) characters.")
        }
        if length > limit {
            problems.append("Too long. This plate type allows up to \(limit) characters.")
        }
        return PlateCheckResult(cleaned: cleaned, problems: problems)
    }

    /// Generates alternative spellings that tend to fit plate limits.
    static func variations(for raw: String, state: StateInfo, maxLength: Int? = nil) -> [String] {
        let limit = maxLength ?? state.maxLength
        let base = raw.uppercased().filter { $0.isLetter || $0.isNumber }
        guard !base.isEmpty else { return [] }

        var results: [String] = []

        // Leet-style swaps
        let swaps: [Character: Character] = ["O": "0", "I": "1", "E": "3", "S": "5", "A": "4"]
        for (letter, digit) in swaps where base.contains(letter) {
            results.append(String(base.map { $0 == letter ? digit : $0 }))
        }

        // Drop vowels (keep the first character)
        let first = base.prefix(1)
        let rest = base.dropFirst().filter { !"AEIOU".contains($0) }
        results.append(String(first) + rest)

        // Trim to the limit
        if base.count > limit {
            results.append(String(base.prefix(limit)))
        }

        // Add a trailing number
        for n in ["1", "2", "7"] {
            results.append(base + n)
        }

        var seen = Set<String>([base])
        return results
            .filter { $0.count >= state.minLength && $0.count <= limit }
            .filter { seen.insert($0).inserted }
            .prefix(8)
            .map { $0 }
    }
}

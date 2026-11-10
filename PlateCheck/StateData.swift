import Foundation

struct PlateType: Identifiable, Hashable {
    let name: String
    let maxLength: Int
    var id: String { name }
}

/// Per-state plate rules.
/// IMPORTANT: these limits are approximate defaults. Only a few states are set
/// to non-default values below, and none were verified against each DMV.
/// Edit `maxLength` / `minLength` for your state, and treat the DMV's own
/// checker as the final answer.
struct StateInfo: Identifiable, Hashable {
    let code: String
    let name: String
    var minLength: Int = 2
    var maxLength: Int = 7
    var allowsSpace: Bool = true
    /// Optional direct link to the state's official personalized-plate checker.
    /// Left empty by default; fill in the ones you use. When empty, the app
    /// falls back to a web search for the state's checker.
    var checkerURL: String = ""
    /// Optional plate types with their own character limits (verified for Utah only).
    var plateTypes: [PlateType] = []
    /// Optional state-specific note shown under the checker button.
    var note: String = ""

    var id: String { code }

    var checkerLink: URL? {
        if let url = URL(string: checkerURL), !checkerURL.isEmpty {
            return url
        }
        let query = "\(name) DMV personalized license plate availability check"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }
}

enum StateData {
    static let all: [StateInfo] = [
        StateInfo(code: "AL", name: "Alabama"),
        StateInfo(code: "AK", name: "Alaska"),
        StateInfo(code: "AZ", name: "Arizona"),
        StateInfo(code: "AR", name: "Arkansas"),
        StateInfo(code: "CA", name: "California"),
        StateInfo(code: "CO", name: "Colorado"),
        StateInfo(code: "CT", name: "Connecticut"),
        StateInfo(code: "DE", name: "Delaware"),
        StateInfo(code: "DC", name: "District of Columbia"),
        StateInfo(code: "FL", name: "Florida"),
        StateInfo(code: "GA", name: "Georgia"),
        StateInfo(code: "HI", name: "Hawaii"),
        StateInfo(code: "ID", name: "Idaho"),
        StateInfo(code: "IL", name: "Illinois"),
        StateInfo(code: "IN", name: "Indiana"),
        StateInfo(code: "IA", name: "Iowa"),
        StateInfo(code: "KS", name: "Kansas"),
        StateInfo(code: "KY", name: "Kentucky"),
        StateInfo(code: "LA", name: "Louisiana"),
        StateInfo(code: "ME", name: "Maine"),
        StateInfo(code: "MD", name: "Maryland"),
        StateInfo(code: "MA", name: "Massachusetts", maxLength: 6),
        StateInfo(code: "MI", name: "Michigan"),
        StateInfo(code: "MN", name: "Minnesota"),
        StateInfo(code: "MS", name: "Mississippi"),
        StateInfo(code: "MO", name: "Missouri"),
        StateInfo(code: "MT", name: "Montana"),
        StateInfo(code: "NE", name: "Nebraska"),
        StateInfo(code: "NV", name: "Nevada"),
        StateInfo(code: "NH", name: "New Hampshire"),
        StateInfo(code: "NJ", name: "New Jersey"),
        StateInfo(code: "NM", name: "New Mexico"),
        StateInfo(code: "NY", name: "New York", maxLength: 8),
        StateInfo(code: "NC", name: "North Carolina"),
        StateInfo(code: "ND", name: "North Dakota"),
        StateInfo(code: "OH", name: "Ohio"),
        StateInfo(code: "OK", name: "Oklahoma"),
        StateInfo(code: "OR", name: "Oregon"),
        StateInfo(code: "PA", name: "Pennsylvania"),
        StateInfo(code: "RI", name: "Rhode Island"),
        StateInfo(code: "SC", name: "South Carolina"),
        StateInfo(code: "SD", name: "South Dakota"),
        StateInfo(code: "TN", name: "Tennessee"),
        StateInfo(code: "TX", name: "Texas"),
        // Utah: limits and checker taken from dmv.utah.gov (Personalized Plates
        // page, FAQ and form TC-817). Online checks run through the Motor
        // Vehicle Portal (MVP).
        StateInfo(
            code: "UT",
            name: "Utah",
            checkerURL: "https://mvp.tax.utah.gov",
            plateTypes: [
                PlateType(name: "Standard", maxLength: 7),
                PlateType(name: "Life Elevated (Arches / Skier)", maxLength: 7),
                PlateType(name: "In God We Trust", maxLength: 5),
                PlateType(name: "Special group", maxLength: 5),
                PlateType(name: "Motorcycle", maxLength: 5),
            ],
            note: "Utah doesn't allow punctuation (periods, apostrophes, dashes). Some special group plates allow 6 or 7 characters, and the DMV's own pages list motorcycle plates as 4 or 5, so confirm for your plate type. Availability in the portal doesn't guarantee approval, and the DMV can still reject a combination under its guidelines."
        ),
        StateInfo(code: "VT", name: "Vermont"),
        StateInfo(code: "VA", name: "Virginia"),
        StateInfo(code: "WA", name: "Washington"),
        StateInfo(code: "WV", name: "West Virginia"),
        StateInfo(code: "WI", name: "Wisconsin"),
        StateInfo(code: "WY", name: "Wyoming"),
    ]
}

import Foundation

/// Vehicle details only (make, model, year, etc.).
/// Deliberately does NOT include owner names or addresses.
struct VehicleInfo {
    var make: String?
    var model: String?
    var year: String?
    var color: String?
    var raw: [String: String]
}

enum LookupError: LocalizedError {
    case notConfigured
    case badResponse(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add your data provider's endpoint URL and API key in the Lookup tab settings first."
        case .badResponse(let code):
            return "The provider returned an error (HTTP \(code))."
        case .noData:
            return "No vehicle found for that plate."
        }
    }
}

protocol PlateLookupService {
    func lookup(plate: String, stateCode: String) async throws -> VehicleInfo
}

/// Generic client for a paid plate-to-vehicle data provider.
///
/// Every provider has its own URL shape and JSON format, so this is a starting
/// point: it sends a GET request with `plate` and `state` query parameters and
/// your key as a Bearer token, then looks for common field names in the JSON.
/// Adjust `buildRequest` and `parse` to match the provider you sign up with.
struct GenericPlateAPI: PlateLookupService {
    let baseURL: String
    let apiKey: String

    func lookup(plate: String, stateCode: String) async throws -> VehicleInfo {
        guard !baseURL.isEmpty, !apiKey.isEmpty,
              var components = URLComponents(string: baseURL) else {
            throw LookupError.notConfigured
        }

        components.queryItems = [
            URLQueryItem(name: "plate", value: plate),
            URLQueryItem(name: "state", value: stateCode),
        ]
        guard let url = components.url else { throw LookupError.notConfigured }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw LookupError.badResponse(http.statusCode)
        }
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> VehicleInfo {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LookupError.noData
        }
        // Flatten top-level values to strings for display.
        var flat: [String: String] = [:]
        for (key, value) in json {
            if let s = value as? String { flat[key] = s }
            else if let n = value as? NSNumber { flat[key] = n.stringValue }
        }
        if flat.isEmpty { throw LookupError.noData }

        func first(_ keys: [String]) -> String? {
            for k in keys {
                if let match = flat.first(where: { $0.key.lowercased() == k }) { return match.value }
            }
            return nil
        }

        return VehicleInfo(
            make: first(["make"]),
            model: first(["model"]),
            year: first(["year", "model_year"]),
            color: first(["color", "colour"]),
            raw: flat
        )
    }
}

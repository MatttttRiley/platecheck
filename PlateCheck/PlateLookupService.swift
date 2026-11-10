import Foundation

/// Baked-in lookup, no settings, no key entry in the app.
///
/// Step 1: CarAPI turns the plate + state into a VIN.
///        Free tier: 100 requests/month across all endpoints, no credit card.
///        Sign up free at carapi.dev and paste the token below.
/// Step 2: NHTSA vPIC decodes the VIN into full vehicle specs.
///        Free, no key, no account, no limits.
///
/// Vehicle details only (make, model, year, etc.).
/// Deliberately does NOT include owner names or addresses.
struct VehicleInfo {
    var vin: String?
    var make: String?
    var model: String?
    var year: String?
    var body: String?
    var engine: String?
    var fuel: String?
    var transmission: String?
    var raw: [String: String]
}

/// Free CarAPI token (carapi.dev, free tier, no card required).
/// Paste your token here. It is a free-tier token with no payment method
/// attached, so the worst case if someone copies it from the public repo
/// is the 100 free lookups for the month get used up; it resets monthly
/// and nothing can ever be charged.
private let carAPIToken = "carapi_b13fc0eefca1aa6e7e0ede8b3fe5b6e4"

enum LookupError: LocalizedError {
    case tokenMissing
    case quotaExceeded
    case badResponse(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .tokenMissing:
            return "The lookup service isn't set up yet (missing CarAPI token)."
        case .quotaExceeded:
            return "Free monthly limit reached (100 lookups/month). It resets next month."
        case .badResponse(let code):
            return "The lookup service returned an error (HTTP \(code))."
        case .noData:
            return "No vehicle found for that plate."
        }
    }
}

protocol PlateLookupService {
    func lookup(plate: String, stateCode: String) async throws -> VehicleInfo
}

struct BakedInPlateLookup: PlateLookupService {
    func lookup(plate: String, stateCode: String) async throws -> VehicleInfo {
        let vin = try await plateToVIN(plate: plate, stateCode: stateCode)
        return try await decodeVIN(vin)
    }

    /// CarAPI: GET /v1/plate-to-vin/{plate}?country=US&state={state}&token={token}
    /// Returns {"plateNumber": ..., "country": ..., "vin": ...}
    private func plateToVIN(plate: String, stateCode: String) async throws -> String {
        guard !carAPIToken.isEmpty, carAPIToken != "YOUR_CARAPI_TOKEN",
              let encoded = plate.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.carapi.dev/v1/plate-to-vin/\(encoded)?country=US&state=\(stateCode)&token=\(carAPIToken)") else {
            throw LookupError.tokenMissing
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429 { throw LookupError.quotaExceeded }
            if !(200...299).contains(http.statusCode) { throw LookupError.badResponse(http.statusCode) }
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vin = json["vin"] as? String, !vin.isEmpty else {
            throw LookupError.noData
        }
        return vin
    }

    /// NHTSA vPIC: GET /api/vehicles/DecodeVin/{vin}?format=json
    /// Returns {"Results": [{"Variable": "Make", "Value": "HONDA"}, ...]}
    private func decodeVIN(_ vin: String) async throws -> VehicleInfo {
        guard let encoded = vin.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/\(encoded)?format=json") else {
            throw LookupError.noData
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw LookupError.badResponse(http.statusCode)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["Results"] as? [[String: Any]] else {
            throw LookupError.noData
        }

        var fields: [String: String] = [:]
        for row in results {
            if let variable = row["Variable"] as? String,
               let value = row["Value"] as? String,
               !value.isEmpty {
                fields[variable] = value
            }
        }
        guard fields["Make"] != nil || fields["Model"] != nil else {
            throw LookupError.noData
        }

        var engine = fields["Engine Configuration"]
        if let displacement = fields["Displacement (L)"],
           let liters = Double(displacement) {
            let desc = String(format: "%.1fL", liters)
            engine = engine.map { "\($0) \(desc)" } ?? desc
        }

        return VehicleInfo(
            vin: vin,
            make: fields["Make"],
            model: fields["Model"],
            year: fields["Model Year"],
            body: fields["Body Class"],
            engine: engine,
            fuel: fields["Fuel Type - Primary"],
            transmission: fields["Transmission Style"],
            raw: fields
        )
    }
}

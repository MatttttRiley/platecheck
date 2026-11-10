import SwiftUI

struct LookupView: View {
    @AppStorage("selectedState") private var stateCode = "UT"

    @State private var plate = ""
    @State private var isLoading = false
    @State private var vehicle: VehicleInfo?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Plate") {
                    Picker("State", selection: $stateCode) {
                        ForEach(StateData.all) { s in
                            Text("\(s.name) (\(s.code))").tag(s.code)
                        }
                    }
                    TextField("Plate number", text: $plate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.title2, design: .monospaced))

                    Button {
                        Task { await search() }
                    } label: {
                        HStack {
                            Text("Look up vehicle")
                            if isLoading { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(plate.isEmpty || isLoading)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                if let vehicle {
                    Section("Vehicle") {
                        row("Year", vehicle.year)
                        row("Make", vehicle.make)
                        row("Model", vehicle.model)
                        row("VIN", vehicle.vin)
                        row("Body", vehicle.body)
                        row("Engine", vehicle.engine)
                        row("Fuel", vehicle.fuel)
                        row("Transmission", vehicle.transmission)
                    }
                }

                Section {
                    Text("Free lookups: the plate is matched to a VIN (CarAPI, 100 free lookups a month), then the VIN is decoded into full specs by NHTSA. This app returns vehicle details only, never owner information. Use lookups lawfully and respect people's privacy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Plate Lookup")
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            LabeledContent(label, value: value)
        }
    }

    private func search() async {
        isLoading = true
        errorMessage = nil
        vehicle = nil
        defer { isLoading = false }

        let service = BakedInPlateLookup()
        do {
            vehicle = try await service.lookup(
                plate: plate.uppercased().replacingOccurrences(of: " ", with: ""),
                stateCode: stateCode
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

import SwiftUI

struct VanityCheckView: View {
    @AppStorage("selectedState") private var stateCode = "UT"
    @State private var plateTypeName = ""
    @State private var plateText = ""
    @State private var result: PlateCheckResult?
    @State private var suggestions: [String] = []
    @Environment(\.openURL) private var openURL

    private var state: StateInfo {
        StateData.all.first { $0.code == stateCode } ?? StateData.all[0]
    }

    /// Character limit for the selected plate type, or the state default.
    private var effectiveMax: Int {
        state.plateTypes.first { $0.name == plateTypeName }?.maxLength
            ?? state.plateTypes.first?.maxLength
            ?? state.maxLength
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("State") {
                    Picker("State", selection: $stateCode) {
                        ForEach(StateData.all) { s in
                            Text("\(s.name) (\(s.code))").tag(s.code)
                        }
                    }
                    .onChange(of: stateCode) { _, _ in
                        plateTypeName = state.plateTypes.first?.name ?? ""
                        runCheck()
                    }

                    if !state.plateTypes.isEmpty {
                        Picker("Plate type", selection: $plateTypeName) {
                            ForEach(state.plateTypes) { t in
                                Text("\(t.name) (up to \(t.maxLength))").tag(t.name)
                            }
                        }
                        .onChange(of: plateTypeName) { _, _ in runCheck() }
                    }
                }

                Section("Your plate") {
                    TextField("e.g. GOHAWKS", text: $plateText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.title2, design: .monospaced))
                        .onChange(of: plateText) { _, _ in runCheck() }

                    Text("Limit: \(effectiveMax) characters")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let result, !plateText.isEmpty {
                    Section("Format check") {
                        if result.isValidFormat {
                            Label("Fits \(state.name)'s basic format", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            ForEach(result.problems, id: \.self) { problem in
                                Label(problem, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    if !suggestions.isEmpty {
                        Section("Variations that fit") {
                            ForEach(suggestions, id: \.self) { s in
                                Button {
                                    plateText = s
                                } label: {
                                    Text(s).font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                    }

                    Section {
                        Button {
                            if let url = state.checkerLink { openURL(url) }
                        } label: {
                            Label("Check availability on \(state.name)'s site", systemImage: "safari")
                        }
                    } footer: {
                        Text("No state offers a public availability API, so the final answer has to come from the official DMV checker. Offensive or reserved combinations may also be rejected even if they look available.\(state.note.isEmpty ? "" : "\n\n" + state.note)")
                    }
                }
            }
            .navigationTitle("Vanity Plates")
            .onAppear {
                if plateTypeName.isEmpty { plateTypeName = state.plateTypes.first?.name ?? "" }
            }
        }
    }

    private func runCheck() {
        guard !plateText.isEmpty else {
            result = nil
            suggestions = []
            return
        }
        result = PlateRules.check(plateText, state: state, maxLength: effectiveMax)
        suggestions = PlateRules.variations(for: plateText, state: state, maxLength: effectiveMax)
    }
}

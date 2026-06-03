import SwiftUI
import UniformTypeIdentifiers

struct ConfigView: View {
    @AppStorage("config_clientId") private var clientId: String = ""
    @AppStorage("config_memberId") private var memberId: String = ""
    @AppStorage("config_privateKey") private var privateKey: String = ""
    @AppStorage("config_beurl") private var beurl: String = ""
    @AppStorage("config_gymLocationId") private var gymLocationId: String = ""

    @State private var showFileImporter = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Client ID") {
                    TextField("e.g. rmwabrand", text: $clientId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Gym Location ID") {
                    TextField("e.g. 999", text: $gymLocationId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Backend URL") {
                    TextField("e.g. https://api.example.com", text: $beurl)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Member ID") {
                    TextField("e.g. 22205900226191", text: $memberId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.numberPad)
                }

                Section("RSA Private Key (PKCS8 PEM)") {
                    if privateKey.isEmpty {
                        Text("No key loaded")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Key loaded (\(privateKey.count) chars)")
                            .foregroundStyle(.green)
                    }

                    Button("Import .pem / .key file") {
                        showFileImporter = true
                    }

                    Button("Clear Key", role: .destructive) {
                        privateKey = ""
                    }
                    .disabled(privateKey.isEmpty)
                }

                Section {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle("JWT Configuration")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url),
                       let content = String(data: data, encoding: .utf8) {
                        privateKey = content
                    }
                case .failure(let error):
                    print("File import error: \(error.localizedDescription)")
                }
            }
        }
    }
}

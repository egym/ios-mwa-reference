import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct ConfigView: View {
    @AppStorage("config_clientId") private var clientId: String = ""
    @AppStorage("config_memberId") private var memberId: String = ""
    @AppStorage("config_privateKey") private var privateKey: String = ""
    @AppStorage("config_beurl") private var beurl: String = ""
    @AppStorage("config_gymLocationId") private var gymLocationId: String = ""
    @AppStorage("config_locale") private var locale: String = "en-US"

    private let availableLocales = [
        "ar-AE", "be-BY", "bg-BG", "ca-ES", "cs-CZ", "cy-GB", "da-DK",
        "de-DE", "el-GR", "en-AU", "en-CA", "en-GB", "en-US", "es-419",
        "es-ES", "es-MX", "fi-FI", "fr-CA", "fr-FR", "he-IL", "is-IS",
        "it-IT", "ja-JP", "ko-KR", "nb-NO", "nl-BE", "nl-NL", "pl-PL",
        "pt-PT", "ro-RO", "ru-RU", "sv-SE", "th-TH", "tr-TR", "uk-UA",
        "zh-CN", "zh-Hans-CN", "zh-TW"
    ]

    @State private var showFileImporter = false
    @State private var tokensClearedMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Gym Location ID") {
                    TextField("e.g. 999", text: $gymLocationId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Locale") {
                    Picker("Language", selection: $locale) {
                        ForEach(availableLocales, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
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

                Section("Client ID (optional)") {
                    TextField("e.g. rmwabrand", text: $clientId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Backend URL (optional)") {
                    TextField("e.g. https://api.example.com", text: $beurl)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Tokens") {
                    Button("Clear Access & Refresh Tokens + Cookies", role: .destructive) {
                        let defaults = UserDefaults.standard
                        let allKeys = defaults.dictionaryRepresentation().keys
                        for key in allKeys {
                            let lower = key.lowercased()
                            if lower.contains("token") || lower.contains("access") || lower.contains("refresh") {
                                defaults.removeObject(forKey: key)
                            }
                        }
                        defaults.synchronize()

                        // Clear HTTPCookieStorage
                        if let cookies = HTTPCookieStorage.shared.cookies {
                            for cookie in cookies {
                                HTTPCookieStorage.shared.deleteCookie(cookie)
                            }
                        }

                        // Clear WKWebView cookies and website data
                        let dataStore = WKWebsiteDataStore.default()
                        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
                        dataStore.removeData(ofTypes: dataTypes, modifiedSince: .distantPast) {
                            print("WebView data cleared")
                        }

                        tokensClearedMessage = "Tokens & cookies cleared!"
                    }
                    if let message = tokensClearedMessage {
                        Text(message)
                            .foregroundStyle(.green)
                            .font(.footnote)
                    }
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

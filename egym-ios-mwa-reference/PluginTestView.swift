#if DEBUG
import SwiftUI
import WebKit
import os
import EgymMwaNavigationPlugin

/// Debug builds only: the Workouts Portal with buttons that call EgymMwaNavigation.open from its WebView,
/// the way the Workouts demo button does.
struct PluginTestView: View {
    private struct HostRequest: Decodable {
        let type: String
    }

    private static let logger = Logger(subsystem: "com.alexkolomiytsev.egym-ios-mwa-reference", category: "PluginTest")

    let workoutsPortal: Portal
    let nfcChannel: String

    @Environment(\.dismiss) private var dismiss
    @State private var webView: WKWebView?
    @State private var results: [String] = []

    var body: some View {
        LiveUpdatePortalView(
            portal: workoutsPortal,
            onBridgeAvailable: { bridge in Task { webView = bridge.webView } },
            onClose: { dismiss() }
        )
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plugin test").font(.headline)
                    HStack {
                        Button("Open NFC") { open(appId: "dcbe378a") }
                        Button("Open twice") {
                            open(appId: "dcbe378a")
                            open(appId: "dcbe378a")
                        }
                        Button("Other app") { open(appId: "068a3720") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(webView == nil)
                    ForEach(results.indices, id: \.self) { index in
                        Text(results[index]).font(.caption.monospaced())
                    }
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 12))
                .padding()
            }
            .task {
                for await event in PortalsPubSub.subscribe(to: "subscription") {
                    if (try? event.decodeData(as: HostRequest.self))?.type == "dismiss" {
                        dismiss()
                    }
                }
            }
    }

    private func open(appId: String) {
        var initialContext = workoutsPortal.initialContext
        initialContext["startingRoute"] = "/nfc/home"
        let options: [String: Any] = ["appId": appId, "channel": nfcChannel, "startingRoute": "/nfc/home", "initialContext": initialContext]
        guard let webView, let json = try? JSONSerialization.data(withJSONObject: options) else { return }

        Task {
            let result = try? await webView.callAsyncJavaScript(
                """
                return Capacitor.nativePromise('EgymMwaNavigation', 'open', JSON.parse(options))
                  .then((result) => 'closedBy: ' + result.closedBy, (error) => 'rejected: ' + error.code);
                """,
                arguments: ["options": String(decoding: json, as: UTF8.self)],
                contentWorld: .page
            )
            let line = "\(appId) \(result as? String ?? "no result")"
            Self.logger.info("open of \(line, privacy: .public)")
            results.append(line)
        }
    }
}
#endif

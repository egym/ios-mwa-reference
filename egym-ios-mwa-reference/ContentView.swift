import SwiftUI
import IonicPortals
import IonicLiveUpdates
import CapacitorNFCPassWalletPlugin
import PreferencesPlugin

typealias JSONObject = [String: Any]

#if DEBUG
let IS_WEB_DEBUGGABLE = true
#else
let IS_WEB_DEBUGGABLE = false
#endif

struct ContentView: View {
  #if canImport(IonicPortals)

  @AppStorage("config_clientId") private var clientId: String = ""
  @AppStorage("config_memberId") private var memberId: String = ""
  @AppStorage("config_privateKey") private var privateKey: String = ""
  @AppStorage("config_beurl") private var beurl: String = ""
  @AppStorage("config_gymLocationId") private var gymLocationId: String = ""
  @AppStorage("config_locale") private var locale: String = "en-US"

  private var memberIdJWT: String? {
      guard !memberId.isEmpty, !privateKey.isEmpty else { return nil }
      return try? JWTGenerator.generateMembershipJWT(memberId: memberId, privateKeyPEM: privateKey)
  }

  private func makeContext(startingRoute: String) -> [String: String] {
      var ctx: [String: String] = [
          "startingRoute": startingRoute,
          "email": "email@example.com",
          "firstName": "Oleksandr",
          "lastName": "Usyk",
          "dateOfBirth": "1990-01-01",
          "gymLocation": "DE01",
          "language": locale,
          "measurementSystem": "METRIC",
          "gender": "MALE",
          "cardNumber": "000123123123",
          "showLogger": "true"
      ]
      if !clientId.isEmpty {
          ctx["clientId"] = clientId
      }
      if !gymLocationId.isEmpty {
          ctx["gymLocation"] = gymLocationId
      }
      if let jwt = memberIdJWT {
          ctx["memberId"] = jwt
      }
      if !beurl.isEmpty {
          ctx["url"] = beurl
      }
      print("[Portal Context] \(startingRoute): \(ctx)")
      return ctx
  }

  private func workoutsPortal() -> Portal {
      Portal(
          name: "egym-workouts",
          startDir: "portals/webdir",
          initialContext: makeContext(startingRoute: "/workouts/home"),
          plugins: [.type(PreferencesPlugin.self), .type(CapacitorNFCPassWalletPlugin.self)],
          liveUpdateConfig: LiveUpdate(
              appId: "851e0894",
              channel: "reference",
              syncOnAdd: true
          )
      ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)
  }

  private func bioagePortal() -> Portal {
      Portal(
          name: "egym-bioage",
          startDir: "portals/webdir",
          initialContext: makeContext(startingRoute: "/bioage/home"),
          plugins: [.type(PreferencesPlugin.self), .type(CapacitorNFCPassWalletPlugin.self)],
          liveUpdateConfig: LiveUpdate(
              appId: "068a3720",
              channel: "reference",
              syncOnAdd: true
          )
      ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)
  }

  private func nfcPortal() -> Portal {
      Portal(
          name: "egym-nfc",
          startDir: "portals/webdir",
          initialContext: makeContext(startingRoute: "/nfc/home"),
          plugins: [.type(PreferencesPlugin.self), .type(CapacitorNFCPassWalletPlugin.self)],
          liveUpdateConfig: LiveUpdate(
              appId: "dcbe378a",
              channel: "egymdevelop",
              syncOnAdd: true
          )
      ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)
  }
  #endif

  @State private var showWorkoutsWebApp = false
  @State private var showBioageWebApp = false
  @State private var showNfcWebApp = false
  @State private var showConfig = false
  @State private var dismissListener: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")

      #if canImport(IonicPortals)
      Button("⚙️ JWT Config") { showConfig = true }
        .sheet(isPresented: $showConfig) {
            ConfigView()
        }

      Button("Workouts MWA") { showWorkoutsWebApp = true }
        .fullScreenCover(isPresented: $showWorkoutsWebApp, onDismiss: {
            // cleanup when modal goes away
            dismissListener?.cancel()
            dismissListener = nil
        }) {
            PortalView(portal: workoutsPortal())
                .onAppear {
                    dismissListener?.cancel()
                    dismissListener = Task {
                        for await event in PortalsPubSub.subscribe(to: "subscription") {
                
                            struct ClosePayload: Decodable { let type: String? }
                            if let decoded = try? event.decodeData(as: ClosePayload.self) {
                                print("Decoded reason:", decoded.type ?? "n/a")
                                
                                if decoded.type == "dismiss" {
                                    await MainActor.run { showWorkoutsWebApp = false }
                                }
                            }
                        }
                    }
                }
        }
        
    Button("Bioage MWA") { showBioageWebApp = true }
      .fullScreenCover(isPresented: $showBioageWebApp, onDismiss: {
          // cleanup when modal goes away
          dismissListener?.cancel()
          dismissListener = nil
      }) {
          PortalView(portal: bioagePortal())
              .onAppear {
                  dismissListener?.cancel()
                  dismissListener = Task {
                      for await event in PortalsPubSub.subscribe(to: "subscription") {
              
                          struct ClosePayload: Decodable { let type: String? }
                          if let decoded = try? event.decodeData(as: ClosePayload.self) {
                              print("Decoded reason:", decoded.type ?? "n/a")
                              
                              if decoded.type == "dismiss" {
                                  await MainActor.run { showBioageWebApp = false }
                              }
                          }
                      }
                  }
              }
      }

      Button("NFC MWA") { showNfcWebApp = true }
      .fullScreenCover(isPresented: $showNfcWebApp, onDismiss: {
          // cleanup when modal goes away
          dismissListener?.cancel()
          dismissListener = nil
      }) {
          PortalView(portal: nfcPortal())
            .onAppear {
              dismissListener?.cancel()
              dismissListener = Task {
                  for await event in PortalsPubSub.subscribe(to: "subscription") {
                      struct ClosePayload: Decodable { let type: String? }
                      if let decoded = try? event.decodeData(as: ClosePayload.self) {
                          print("Decoded reason:", decoded.type ?? "n/a")
                          
                          if decoded.type == "dismiss" {
                              await MainActor.run { showNfcWebApp = false }
                          }
                      }
                  }
              }
            }
      }
      #else
      Text("Ionic Portals not available.")
        .font(.footnote)
        .foregroundStyle(.secondary)
      #endif
    }
    .padding()
  }
}

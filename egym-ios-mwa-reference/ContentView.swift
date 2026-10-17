import SwiftUI
import EgymMwaNavigationPlugin

typealias JSONObject = [String: Any]

#if DEBUG
let IS_WEB_DEBUGGABLE = true
#else
let IS_WEB_DEBUGGABLE = false
#endif

struct ContentView: View {
  #if canImport(IonicPortals)
    
  private static let egymWorkoutsPortal = Portal(
    name: "egym-workouts",
    startDir: "portals/webdir",
    initialContext: [
        "startingRoute": "/workouts/home",
        "email": "email@example.com",
        "firstName": "Oleksandr",
        "lastName": "Usyk",
        "dateOfBirth": "1990-01-01",
        "gymLocation": "DE01",
        "language": "de-DE",
        "measurementSystem": "METRIC",
        "gender": "MALE",
//          "memberId": "jwt", // unique member id signed in JWT
        "cardNumber": "000123123123" // 12 digit number with leading zeros
      ],
    plugins: EgymMwa.portalPlugins,
    liveUpdateConfig: LiveUpdate(
      appId: "851e0894",
      channel: "reference",
      syncOnAdd: false
    ),
  ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)
    
  private static let egymBioagePortal = Portal(
    name: "egym-bioage",
    startDir: "portals/webdir",
    initialContext: [
        "startingRoute": "/bioage/home",
        "email": "email@example.com",
        "firstName": "Oleksandr",
        "lastName": "Usyk",
        "dateOfBirth": "1990-01-01",
        "gymLocation": "DE01",
        "language": "de-DE",
        "measurementSystem": "METRIC",
        "gender": "MALE",
//          "memberId": "jwt", // unique member id signed in JWT
        "cardNumber": "000123123123" // 12 digit number with leading zeros
      ],
    plugins: EgymMwa.portalPlugins,
    liveUpdateConfig: LiveUpdate(
      appId: "068a3720",
      channel: "reference",
      syncOnAdd: false
    ),
  ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)

  private static let egymNfcPortal = Portal(
    name: "egym-nfc",
    startDir: "portals/webdir",
    initialContext: [
        "startingRoute": "/nfc/home",
        "email": "email@example.com",
        "firstName": "Oleksandr",
        "lastName": "Usyk",
        "dateOfBirth": "1990-01-01",
        "gymLocation": "DE01",
        "language": "de-DE",
        "measurementSystem": "METRIC",
        "gender": "MALE",
//          "memberId": "jwt", // unique member id signed in JWT
        "cardNumber": "000123123123" // 12 digit number with leading zeros
      ],
    plugins: EgymMwa.portalPlugins,
    liveUpdateConfig: LiveUpdate(
      appId: "dcbe378a",
      channel: "reference",
      syncOnAdd: false
    ),
  ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)

  // nil keeps the sample Portal, which is created on its first open.
  var workoutsPortal: Portal?
  var nfcPortal: Portal?
  #endif

  @State private var showWorkoutsWebApp = false
  @State private var showBioageWebApp = false
  @State private var showNfcWebApp = false
  @State private var dismissListener: Task<Void, Never>?
  #if DEBUG
  @State private var showPluginTest = false
  #endif

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")

      #if canImport(IonicPortals)
      Button("Workouts MWA") { showWorkoutsWebApp = true }
        .fullScreenCover(isPresented: $showWorkoutsWebApp, onDismiss: {
            // cleanup when modal goes away
            dismissListener?.cancel()
            dismissListener = nil
        }) {
            LiveUpdatePortalView(portal: workoutsPortal ?? Self.egymWorkoutsPortal) { showWorkoutsWebApp = false }
                .ignoresSafeArea()
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
          LiveUpdatePortalView(portal: Self.egymBioagePortal) { showBioageWebApp = false }
              .ignoresSafeArea()
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
          LiveUpdatePortalView(portal: nfcPortal ?? Self.egymNfcPortal) { showNfcWebApp = false }
              .ignoresSafeArea()
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

      #if DEBUG
      Button("Plugin test") { showPluginTest = true }
        .fullScreenCover(isPresented: $showPluginTest) {
          PluginTestView(
            workoutsPortal: workoutsPortal ?? Self.egymWorkoutsPortal,
            nfcChannel: (nfcPortal ?? Self.egymNfcPortal).liveUpdateConfig?.channel ?? "reference"
          )
        }
      #endif
      #else
      Text("Ionic Portals not available.")
        .font(.footnote)
        .foregroundStyle(.secondary)
      #endif
    }
    .padding()
  }
}

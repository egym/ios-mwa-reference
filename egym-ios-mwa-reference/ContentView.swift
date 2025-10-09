import SwiftUI
import IonicPortals
import IonicLiveUpdates
import PreferencesPlugin

typealias JSONObject = [String: Any]

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
    plugins: [.type(PreferencesPlugin.self)],
    liveUpdateConfig: LiveUpdate(
      appId: "851e0894",
      channel: "sportcitydevelop",
      syncOnAdd: true
    ),
  );
    
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
    plugins: [.type(PreferencesPlugin.self)],
    liveUpdateConfig: LiveUpdate(
      appId: "068a3720",
      channel: "sportcitydevelop",
      syncOnAdd: true
    ),
  )
  #endif

  @State private var showWorkoutsWebApp = false
  @State private var showBioageWebApp = false
  @State private var dismissListener: Task<Void, Never>?

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
            PortalView(portal: Self.egymWorkoutsPortal)
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
          PortalView(portal: Self.egymBioagePortal)
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
      #else
      Text("Ionic Portals not available.")
        .font(.footnote)
        .foregroundStyle(.secondary)
      #endif
    }
    .padding()
  }
}

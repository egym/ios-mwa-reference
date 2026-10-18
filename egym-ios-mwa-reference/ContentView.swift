import SwiftUI
import EgymMwaNavigationPlugin

/// A logged-in BMA member: Workouts and NFC open with this context on this channel.
struct LoggedInMember {
  let initialContext: [String: Any]
  let channel: String
}

struct ContentView: View {
  // nil opens Workouts and NFC with the sample context on the channel reference.
  var member: LoggedInMember?

  private static let sampleContext: [String: Any] = [
    "email": "email@example.com",
    "firstName": "Oleksandr",
    "lastName": "Usyk",
    "dateOfBirth": "1990-01-01",
    "gymLocation": "DE01",
    "language": "de-DE",
    "measurementSystem": "METRIC",
    "gender": "MALE",
//    "memberId": "jwt", // unique member id signed in JWT
    "cardNumber": "000123123123" // 12 digit number with leading zeros
  ]

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")

      Button("Workouts MWA") { open(appId: "851e0894", startingRoute: "/workouts/home", as: member) }
      // Bioage always runs with the sample context.
      Button("Bioage MWA") { open(appId: "068a3720", startingRoute: "/bioage/home", as: nil) }
      Button("NFC MWA") { open(appId: "dcbe378a", startingRoute: "/nfc/home", as: member) }
      // The web reference MWA (egym/mwa-reference) demos the EGYM plugins, the MWA navigation plugin among them.
      Button("Reference MWA") { open(appId: "9d727e58", startingRoute: "/home", as: nil, channel: "develop") }
    }
    .padding()
  }

  /// The package shows the MWA full screen, loads its live update first and closes it on dismiss.
  private func open(appId: String, startingRoute: String, as member: LoggedInMember?, channel: String = "reference") {
    let options = EgymMwaOpenOptions(
      appId: appId,
      channel: member?.channel ?? channel,
      startingRoute: startingRoute,
      initialContext: member?.initialContext ?? Self.sampleContext
    )
    let status = EgymMwa.open(options) { reason in
      print("\(appId) closed by \(reason.rawValue)")
    }
    if status != .opened {
      print("\(appId) did not open: \(status.rawValue)")
    }
  }
}

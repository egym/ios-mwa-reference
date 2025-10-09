import SwiftUI
import IonicPortals

@main
struct egym_ios_mwa_referenceApp: App {
    init() {
       PortalsRegistrationManager.shared.register(key: "<put portals key here>")
     }

     var body: some Scene {
       WindowGroup { ContentView() }
     }
}

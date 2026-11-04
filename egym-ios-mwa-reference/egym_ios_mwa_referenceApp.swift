import SwiftUI

@main
struct egym_ios_mwa_referenceApp: App {
    private let bmaLoginConfig = BMALoginConfig.load()

    var body: some Scene {
        WindowGroup {
            if let bmaLoginConfig {
                BMALoginView(config: bmaLoginConfig)
            } else {
                ContentView()
            }
        }
    }
}

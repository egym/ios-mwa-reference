import Foundation

/// The git-ignored `BMALogin.json` turns on the BMA login; without it the app runs with the sample context.
struct BMALoginConfig: Decodable {
    let galaxyURL: URL
    let mwaApiURL: URL
    let liveUpdateChannel: String

    static func load(from bundle: Bundle = .main) -> BMALoginConfig? {
        guard let url = bundle.url(forResource: "BMALogin", withExtension: "json") else {
            return nil
        }
        do {
            return try JSONDecoder().decode(BMALoginConfig.self, from: Data(contentsOf: url))
        } catch {
            fatalError("BMALogin.json cannot be read: \(error)")
        }
    }
}

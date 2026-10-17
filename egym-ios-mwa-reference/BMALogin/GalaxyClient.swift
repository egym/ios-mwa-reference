import Foundation

/// Logs in at Galaxy and fetches the member's MWA token, the way the BMA apps get it.
final class GalaxyClient {
    struct Exerciser: Decodable {
        let uuid: String
        let homeClubUuid: String
        let email: String
    }

    enum Failure: LocalizedError {
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .httpStatus(let status): "Galaxy answered with HTTP \(status)."
            }
        }
    }

    private struct MWAToken: Decodable {
        let accessToken: String
    }

    private let baseURL: URL
    // Keeps the JSESSIONID cookie of the login in memory for the token calls.
    private let session = URLSession(configuration: .ephemeral)
    private let deviceUid = UUID().uuidString

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func logIn(email: String, password: String) async throws -> Exerciser {
        // The member login of the BMA apps; /np/login with club_portal is the staff login and refuses members.
        var request = URLRequest(url: baseURL.appending(path: "np/exerciser/login"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("1.5", forHTTPHeaderField: "X-NP-API-Version")
        request.setValue(
            "clientType=MOBILE_DEVICE; devicePlatform=IOS; deviceUid=\(deviceUid); applicationName=RevGen; applicationVersion=100.0; applicationVersionCode=8598;",
            forHTTPHeaderField: "X-NP-User-Agent"
        )
        request.httpBody = Self.formBody(["username": email, "password": password])
        return try await send(request)
    }

    func fetchMWAToken(exerciserUuid: String) async throws -> String {
        let url = baseURL.appending(path: "np/micro-web-app/v1.0/exercisers/\(exerciserUuid)/tokens/FLS")
        let token: MWAToken = try await send(URLRequest(url: url))
        return token.accessToken
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw Failure.httpStatus(status)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private static func formBody(_ fields: KeyValuePairs<String, String>) -> Data {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+"))
        let body = fields
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")" }
            .joined(separator: "&")
        return Data(body.utf8)
    }
}

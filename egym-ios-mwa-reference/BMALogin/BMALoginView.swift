import SwiftUI
import EgymMwaNavigationPlugin

/// The "auth as BMA user" screen. After the login, Workouts and NFC open as this member.
struct BMALoginView: View {
    private struct Session {
        let galaxy: GalaxyClient
        let exerciser: GalaxyClient.Exerciser
        var token: String
    }

    private struct HostRequest: Decodable {
        let type: String
    }

    let config: BMALoginConfig

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoggingIn = false
    @State private var errorMessage: String?
    @State private var session: Session?

    var body: some View {
        if let session {
            ContentView(member: member(of: session))
                .task { await answerAuthTokenRequests(in: session) }
        } else {
            NavigationStack {
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        }
                    }
                    Section {
                        Button {
                            Task { await logIn() }
                        } label: {
                            if isLoggingIn {
                                ProgressView()
                            } else {
                                Text("Log in")
                            }
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoggingIn)
                    } footer: {
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(.red)
                        }
                    }
                }
                .navigationTitle("Auth as BMA user")
            }
        }
    }

    private func logIn() async {
        guard !isLoggingIn else { return }
        isLoggingIn = true
        errorMessage = nil
        defer { isLoggingIn = false }

        let galaxy = GalaxyClient(baseURL: config.galaxyURL)
        do {
            let exerciser = try await galaxy.logIn(email: email, password: password)
            let token = try await galaxy.fetchMWAToken(exerciserUuid: exerciser.uuid)
            password = ""
            session = Session(galaxy: galaxy, exerciser: exerciser, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // The context the BMA apps send, without mwaProtocolVersion: this host does not handle trackEvent.
    private func member(of session: Session) -> LoggedInMember {
        LoggedInMember(
            initialContext: [
                "clientId": "egym",
                "authToken": session.token,
                "url": config.mwaApiURL.absoluteString,
                "gymLocation": session.exerciser.homeClubUuid,
                "email": session.exerciser.email,
                "language": "en-US",
                "preferences": [String: Any](),
                "linking": ["status": "linked", "egymEmail": session.exerciser.email],
            ],
            channel: config.liveUpdateChannel
        )
    }

    private func answerAuthTokenRequests(in session: Session) async {
        for await event in PortalsPubSub.subscribe(to: "subscription") {
            guard (try? event.decodeData(as: HostRequest.self))?.type == "authToken" else { continue }
            do {
                let token = try await session.galaxy.fetchMWAToken(exerciserUuid: session.exerciser.uuid)
                PortalsPubSub.publish(token, to: "authToken")
                // The next open starts with the new token.
                self.session?.token = token
            } catch GalaxyClient.Failure.httpStatus(let status, _) where status == 401 || status == 403 {
                EgymMwa.close()
                errorMessage = "The Galaxy session has ended. Log in again."
                self.session = nil
                return
            } catch {
                print("Could not renew the MWA token:", error.localizedDescription)
            }
        }
    }
}

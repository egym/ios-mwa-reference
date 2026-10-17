import SwiftUI
import IonicPortals
import IonicLiveUpdates
import Capacitor
import CapacitorNFCPassWalletPlugin
import PreferencesPlugin

/// The "auth as BMA user" screen. After the login, Workouts and NFC open as this member.
struct BMALoginView: View {
    private struct Session {
        let workoutsPortal: Portal
        let nfcPortal: Portal
    }

    let config: BMALoginConfig

    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var errorMessage: String?
    @State private var session: Session?

    var body: some View {
        if let session {
            ContentView(workoutsPortal: session.workoutsPortal, nfcPortal: session.nfcPortal)
        } else {
            NavigationStack {
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Password", text: $password)
                            .textContentType(.password)
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
            session = Session(
                workoutsPortal: makePortal(name: "egym-workouts", appId: "851e0894", startingRoute: "/workouts/home", exerciser: exerciser, token: token),
                nfcPortal: makePortal(name: "egym-nfc", appId: "dcbe378a", startingRoute: "/nfc/home", exerciser: exerciser, token: token)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // The context the BMA apps send, without mwaProtocolVersion: this host does not handle trackEvent.
    private func makePortal(name: String, appId: String, startingRoute: String, exerciser: GalaxyClient.Exerciser, token: String) -> Portal {
        Portal(
            name: name,
            startDir: "portals/webdir",
            initialContext: [
                "startingRoute": startingRoute,
                "clientId": "egym",
                "authToken": token,
                "url": config.mwaApiURL.absoluteString,
                "gymLocation": exerciser.homeClubUuid,
                "email": exerciser.email,
                "language": "en-US",
                "preferences": JSObject(),
                "linking": ["status": "linked", "egymEmail": exerciser.email] as JSObject,
            ],
            plugins: [.type(PreferencesPlugin.self), .type(CapacitorNFCPassWalletPlugin.self)],
            liveUpdateConfig: LiveUpdate(appId: appId, channel: config.liveUpdateChannel, syncOnAdd: true)
        ).configuring(\.isWebDebuggable, IS_WEB_DEBUGGABLE)
    }
}

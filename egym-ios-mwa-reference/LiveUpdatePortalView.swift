import SwiftUI
import Capacitor
import IonicPortals
import IonicLiveUpdates

/// Shows a Portal only after its live update is on the device, so the first open of an MWA is never blank.
/// Before every open it syncs the live update for at most 30 seconds, as the BMA apps do.
struct LiveUpdatePortalView: View {
    let portal: Portal
    var onBridgeAvailable: (CapacitorBridge) -> Void = { _ in }
    let onClose: () -> Void

    private enum Phase {
        case loading, ready, failed
    }

    @State private var phase = Phase.loading
    @State private var attempt = 0

    var body: some View {
        switch phase {
        case .ready:
            PortalView(portal: portal, onBridgeAvailable: onBridgeAvailable)
        case .loading:
            VStack(spacing: 16) {
                ProgressView()
                Button("Close", action: onClose)
            }
            .task(id: attempt) {
                phase = await LiveUpdateSync.run(for: portal) ? .ready : .failed
            }
        case .failed:
            VStack(spacing: 16) {
                Text("Could not load this MWA.")
                Button("Try again") {
                    attempt += 1
                    phase = .loading
                }
                Button("Close", action: onClose)
            }
        }
    }
}

enum LiveUpdateSync {
    private static let timeout: TimeInterval = 30

    /// Syncs the live update of the Portal and answers whether a valid build is on the device afterwards.
    /// After a failed sync or the time limit, a build downloaded earlier still counts.
    static func run(for portal: Portal) async -> Bool {
        guard let liveUpdate = portal.liveUpdateConfig else { return true }
        let manager = portal.liveUpdateManager
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let once = Once()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                once.run { continuation.resume() }
            }
            manager.sync(liveUpdate: liveUpdate) { _ in
                once.run { continuation.resume() }
            }
        }
        guard let directory = manager.latestAppDirectory(for: liveUpdate.appId) else { return false }
        return FileManager.default.fileExists(atPath: directory.appendingPathComponent("index.html").path)
    }
}

/// Runs its body once, whichever caller comes first.
private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var hasRun = false

    func run(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasRun else { return }
        hasRun = true
        body()
    }
}

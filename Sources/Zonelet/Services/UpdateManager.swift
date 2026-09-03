import Foundation
import Sparkle

@MainActor
final class UpdateManager: NSObject, SPUUpdaterDelegate, @preconcurrency SPUStandardUserDriverDelegate {
    let isAvailable = Bundle.main.object(
        forInfoDictionaryKey: "ZoneletDistributionBuild"
    ) as? Bool ?? false
    var onGentleUpdateAvailabilityChanged: ((Bool) -> Void)?

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: self
    )

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func start() {
        guard isAvailable else { return }
#if DEBUG
        guard ProcessInfo.processInfo.environment["ZONELET_UI_PREVIEW"] != "1" else { return }
#endif
        updaterController.startUpdater()
    }

    func checkForUpdates() {
        guard isAvailable else { return }
        updaterController.checkForUpdates(nil)
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        if !state.userInitiated {
            onGentleUpdateAvailabilityChanged?(true)
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        onGentleUpdateAvailabilityChanged?(false)
    }

    func standardUserDriverWillFinishUpdateSession() {
        onGentleUpdateAvailabilityChanged?(false)
    }

    func updater(
        _ updater: SPUUpdater,
        willInstallUpdateOnQuit item: SUAppcastItem,
        immediateInstallationBlock immediateInstallHandler: @escaping () -> Void
    ) -> Bool {
        DispatchQueue.main.async {
            immediateInstallHandler()
        }
        return true
    }
}

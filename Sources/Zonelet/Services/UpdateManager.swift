import Foundation
import Sparkle

@MainActor
final class UpdateManager: NSObject, SPUUpdaterDelegate {
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    func start() {
#if DEBUG
        guard ProcessInfo.processInfo.environment["ZONELET_UI_PREVIEW"] != "1" else { return }
#endif
        updaterController.startUpdater()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
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

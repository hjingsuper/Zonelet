import Foundation
import Observation
import ServiceManagement

enum LaunchAtLoginStatus {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
    case failed
}

@MainActor
@Observable
final class LaunchAtLoginManager {
    private enum Keys {
        static let requested = "zonelet.launch-at-login"
    }

    private(set) var isEnabled: Bool
    private(set) var status: LaunchAtLoginStatus = .disabled

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.object(forKey: Keys.requested) as? Bool
        isEnabled = storedValue ?? true

        if storedValue == nil {
            defaults.set(true, forKey: Keys.requested)
        }

#if DEBUG
        if ProcessInfo.processInfo.environment["ZONELET_UI_PREVIEW"] == "1" {
            status = isEnabled ? .enabled : .disabled
            return
        }
#endif

        applyRequestedState()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: Keys.requested)
        applyRequestedState()
    }

    func refresh() {
        updateStatus()
    }

    private let defaults: UserDefaults

    private func applyRequestedState() {
        do {
            if isEnabled {
                switch SMAppService.mainApp.status {
                case .notRegistered, .notFound:
                    try SMAppService.mainApp.register()
                case .enabled, .requiresApproval:
                    break
                @unknown default:
                    break
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
            updateStatus()
        } catch {
            status = .failed
        }
    }

    private func updateStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            status = .enabled
            isEnabled = true
        case .requiresApproval:
            status = .requiresApproval
            isEnabled = true
        case .notRegistered:
            status = .disabled
            isEnabled = false
        case .notFound:
            status = .unavailable
        @unknown default:
            status = .unavailable
        }
    }
}

import Foundation

struct UsageWindow: Codable, Identifiable {
    let utilization: Double
    let resetsAt: String

    var id: String { resetsAt }

    /// Parse ISO 8601 resetsAt into a Date
    var resetsAtDate: Date? {
        ISO8601DateFormatter().date(from: resetsAt)
    }

    var resetDescription: String {
        guard let date = resetsAtDate else { return "—" }
        let remaining = date.timeIntervalSinceNow
        guard remaining > 0 else { return String(localized: "Reset due now") }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        guard let duration = formatter.string(from: remaining) else { return "—" }
        return String(localized: "resets in \(duration)")
    }
}

struct UsageInfo: Codable, Identifiable {
    let provider: String
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let error: String?

    var id: String { provider }

    var displayName: String {
        switch provider {
        case "claude": return "Claude Code"
        case "codex": return "Codex"
        default: return provider
        }
    }

    var iconName: String {
        switch provider {
        case "claude": return "brain.head.profile"
        case "codex": return "chevron.left.forwardslash.chevron.right"
        default: return "questionmark.circle"
        }
    }
}

struct UsageResponse: Codable {
    let providers: [UsageInfo]
}

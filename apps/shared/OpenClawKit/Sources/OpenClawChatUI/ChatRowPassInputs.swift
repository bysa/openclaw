import Foundation

/// Row inputs read from the view model once per transcript pass, not once per row.
struct ChatRowPassInputs {
    let contextWindowTokens: Int?
    /// Each row looks up its own run instead of filtering every live call.
    let liveToolCalls: [String: [OpenClawChatPendingToolCall]]

    static func liveToolCallsByRun(_ calls: [OpenClawChatPendingToolCall]) -> [String: [OpenClawChatPendingToolCall]] {
        var byRun: [String: [OpenClawChatPendingToolCall]] = [:]
        for call in calls {
            guard let runID = call.runID else { continue }
            byRun[runID, default: []].append(call)
        }
        return byRun
    }
}

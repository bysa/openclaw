import Foundation
import OpenClawProtocol

/// Projects only structured steps. A saved completed plan is not a new task.
struct LiveActivityTaskProjection {
    private(set) var sessionKey: String?
    private(set) var state: OpenClawActivityAttributes.ContentState?
    private var cardSessionKey: String?
    private var revision: Int?
    private var suppressedRevision: Int?

    mutating func update(card: ProgressCard?, sessionKey: String, cancel: Bool = false, now: Date = .now) {
        if self.sessionKey != sessionKey {
            self.state = nil
            self.cardSessionKey = nil
            revision = nil
            suppressedRevision = nil
            self.sessionKey = sessionKey
        }
        guard let card, let steps = card.steps, !steps.isEmpty else {
            self.state = nil
            revision = nil
            return
        }
        // The view model admits canonical cards for aliases, including global.
        // Canonical owners scope revisions independently from the focused alias.
        if self.cardSessionKey != card.sessionkey {
            self.state = nil
            revision = nil
            suppressedRevision = nil
            self.cardSessionKey = card.sessionkey
        }
        if cancel {
            suppressedRevision = card.revision
            self.state = nil
            return
        }
        if let suppressedRevision, card.revision <= suppressedRevision {
            return
        }
        if let revision, card.revision <= revision {
            return
        }
        let completed = steps.filter { $0.status == .completed }.count
        let finished = completed == steps.count
        guard !finished || self.state != nil else { return }
        let current = steps.first { $0.status == .inProgress }
        let next = steps.first { $0.status == .pending }
        let updatedAt = Date(timeIntervalSince1970: Double(card.updatedat) / 1000)
        let heading = card.markdown?.split(separator: "\n").first.map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: "# *\t"))
        }
        let title = heading.flatMap { $0.isEmpty ? nil : $0 } ?? "Task progress"
        let task = OpenClawActivityAttributes.ContentState.TaskProgress(
            title: String(title.prefix(120)),
            currentStep: current.map { String($0.step.prefix(180)) },
            nextStep: next.map { String($0.step.prefix(180)) },
            completed: completed,
            total: steps.count,
            phase: finished ? .completed : (current == nil ? .waiting : .working),
            updatedAt: updatedAt)
        self.state = OpenClawActivityAttributes.ContentState(
            status: .toolRunning,
            verbatimDetail: nil,
            startedAt: self.state?.taskProgress?.phase == .completed ? now : (self.state?.startedAt ?? now),
            taskProgress: task)
        revision = card.revision
    }

    /// Repeated observations cannot restart a completed or dismissed revision.
    mutating func retire() {
        self.suppressedRevision = self.revision
        self.state = nil
    }
}

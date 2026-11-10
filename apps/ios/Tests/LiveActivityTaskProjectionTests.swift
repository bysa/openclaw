import Foundation
import OpenClawProtocol
import Testing
@testable import OpenClaw

struct LiveActivityTaskProjectionTests {
    private func card(
        _ revision: Int,
        _ statuses: [ProgressCardStepStatus],
        sessionKey: String = "main") -> ProgressCard
    {
        ProgressCard(
            sessionkey: sessionKey,
            revision: revision,
            updatedat: 100_000,
            markdown: "# Ship update",
            steps: statuses.enumerated()
                .map { ProgressCardStep(step: "Step \($0.offset)", status: $0.element) })
    }

    @Test func `canonical card owner changes reset revision and elapsed time`() {
        var projection = LiveActivityTaskProjection()
        let first = self.card(9, [.inProgress])
        projection.update(card: first, sessionKey: "alias", now: Date(timeIntervalSince1970: 1))
        let other = self.card(1, [.inProgress], sessionKey: "agent:other:main")
        let now = Date(timeIntervalSince1970: 20)
        projection.update(card: other, sessionKey: "alias", now: now)
        #expect(projection.state?.startedAt == now)
        #expect(projection.state?.taskProgress?.phase == .working)
    }

    @Test func `retired completion cannot restart on repeated observations`() {
        var projection = LiveActivityTaskProjection()
        projection.update(card: self.card(1, [.inProgress]), sessionKey: "main")
        projection.update(card: self.card(2, [.completed]), sessionKey: "main")
        projection.retire()
        projection.update(card: self.card(2, [.completed]), sessionKey: "main")
        #expect(projection.state == nil)
        projection.update(card: self.card(1, [.inProgress]), sessionKey: "main")
        #expect(projection.state == nil)
        projection.update(card: self.card(3, [.inProgress]), sessionKey: "main")
        #expect(projection.state?.taskProgress?.phase == .working)
    }

    @Test func `dismissed revision stays retired through missing card hydration`() {
        var projection = LiveActivityTaskProjection()
        projection.update(card: self.card(2, [.inProgress]), sessionKey: "main")
        projection.retire()
        projection.update(card: nil, sessionKey: "main")
        projection.update(card: self.card(2, [.inProgress]), sessionKey: "main")
        #expect(projection.state == nil)
    }

    @Test func `task heartbeat never renews structured freshness and clear restores tool`() {
        var arbiter = LiveActivityPresentationArbiter()
        let state = OpenClawActivityAttributes.ContentState(status: .toolRunning, verbatimDetail: nil, startedAt: .now)
        let task = LiveActivityPresentationRequest(
            state: state,
            staleDate: Date(timeIntervalSince1970: 100),
            agentName: "Test",
            sessionKey: "main")
        var tool = task
        tool.state.toolName = "read"
        arbiter.startTool(id: "tool", request: tool)
        arbiter.setTask(task)
        arbiter.refreshTools(staleDate: .now)
        #expect(arbiter.current == task)
        arbiter.setTask(nil)
        #expect(arbiter.current?.state.toolName == "read")
    }

    @Test func `historical completion does not start`() {
        var projection = LiveActivityTaskProjection()
        projection.update(card: self.card(1, [.completed]), sessionKey: "main")
        #expect(projection.state == nil)
    }

    @Test func `projects only explicit steps and keeps start`() {
        var projection = LiveActivityTaskProjection()
        let start = Date(timeIntervalSince1970: 100)
        projection.update(card: self.card(1, [.completed, .inProgress, .pending]), sessionKey: "main", now: start)
        #expect(projection.state?.taskProgress?.completed == 1)
        #expect(projection.state?.taskProgress?.total == 3)
        #expect(projection.state?.taskProgress?.currentStep == "Step 1")
        #expect(projection.state?.taskProgress?.nextStep == "Step 2")
        #expect(projection.state?.taskProgress?.title == "Ship update")
        projection.update(card: self.card(2, [.completed, .pending]), sessionKey: "main")
        #expect(projection.state?.taskProgress?.phase == .waiting)
        #expect(projection.state?.startedAt == start)
        projection.update(card: self.card(3, [.completed, .completed]), sessionKey: "main")
        #expect(projection.state?.taskProgress?.phase == .completed)
    }

    @Test func `switch clear and cancel do not resurrect completed history`() {
        var projection = LiveActivityTaskProjection()
        projection.update(card: self.card(1, [.inProgress]), sessionKey: "main")
        projection.update(card: self.card(2, [.completed]), sessionKey: "other")
        #expect(projection.state == nil)
        projection.update(card: self.card(3, [.inProgress]), sessionKey: "other")
        projection.update(card: self.card(3, [.inProgress]), sessionKey: "other", cancel: true)
        projection.update(card: self.card(3, [.inProgress]), sessionKey: "other")
        #expect(projection.state == nil)
        projection.update(card: self.card(4, [.inProgress]), sessionKey: "other")
        projection.update(card: nil, sessionKey: "other")
        #expect(projection.state == nil)
    }

    @Test func `task survives tool end and yields to voice and approval`() {
        var arbiter = LiveActivityPresentationArbiter()
        let state = OpenClawActivityAttributes.ContentState(status: .toolRunning, verbatimDetail: nil, startedAt: .now)
        let task = LiveActivityPresentationRequest(state: state, staleDate: .now, agentName: "Test", sessionKey: "main")
        arbiter.setTask(task)
        arbiter.startTool(id: "tool", request: task)
        arbiter.endTool(id: "tool", sessionKey: "main")
        #expect(arbiter.current == task)
        var voice = task
        voice.state.status = .voiceSpeaking
        arbiter.setVoice(voice)
        #expect(arbiter.current == voice)
        var approval = task
        approval.state.status = .approvalNeeded
        arbiter.setAttention(approval)
        #expect(arbiter.current == approval)
        arbiter.setAttention(nil)
        arbiter.setVoice(nil)
        #expect(arbiter.current == task)
        arbiter.clearAll()
        #expect(arbiter.current == nil)
    }

    @Test func `old payload decodes without task and new payload round trips`() throws {
        let json = Data(#"{"status":"toolRunning","startedAt":100}"#.utf8)
        let old = try JSONDecoder().decode(OpenClawActivityAttributes.ContentState.self, from: json)
        #expect(old.taskProgress == nil)
        var projection = LiveActivityTaskProjection()
        projection.update(card: self.card(1, [.inProgress]), sessionKey: "main")
        let state = try #require(projection.state)
        let decoded = try JSONDecoder().decode(
            OpenClawActivityAttributes.ContentState.self,
            from: JSONEncoder().encode(state))
        #expect(decoded == state)
    }
}

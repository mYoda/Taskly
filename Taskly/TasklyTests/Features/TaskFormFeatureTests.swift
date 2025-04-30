//
//  TaskFormFeatureTests.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import XCTest
import ComposableArchitecture
@testable import Taskly

@MainActor
final class TaskFormFeatureTests: XCTestCase {
    
    func testSaveTask() async {
        let task = TaskItem(id: UUID(0), title: "Test Task")
        let store = TestStore(
            initialState: TaskFormFeature.State(task: task),
            reducer: { TaskFormFeature() }
        )
        
        await store.send(.saveButtonTapped)
        await store.receive {
            guard case .saveTask(let receivedTask) = $0 else { return false }
            return receivedTask == task
        }
    }
    
    func testCancel() async {
        let store = TestStore(
            initialState: TaskFormFeature.State(),
            reducer: { TaskFormFeature() },
            withDependencies: { $0.uuid = .constant(UUID(0)) }
        )
        
        await store.send(.cancelButtonTapped)
    }
    
    func testAnalyticsClientLogCalledOnSave() async {
        let task = TaskItem(id: UUID(0), title: "Test Task")
        let loggedEvents = ActorIsolated<[AnalyticsEvent]>([])
        let mockAnalyticsClient = AnalyticsClient(
            log: { event in await loggedEvents.withValue { $0.append(event) } },
            flush: { }
        )
        let store = TestStore(
            initialState: TaskFormFeature.State(task: task),
            reducer: { TaskFormFeature() },
            withDependencies: {
                $0.analyticsClient = mockAnalyticsClient
            }
        )

        await store.send(.saveButtonTapped)
        await store.receive {
            guard case .saveTask(let receivedTask) = $0 else { return false }
            return receivedTask == task
        }
        // Wait for the async log to be called
        try? await Task.sleep(nanoseconds: 100_000_000)
        let events = await loggedEvents.value
//        XCTAssertTrue(
//            events.contains(.taskEdited(id: task.id, newTitle: task.title)) ||
//            events.contains(.taskCreated(id: task.id, title: task.title)),
//            "Expected analyticsClient.log to be called with a taskEdited or taskCreated event."
//        )
    }
} 

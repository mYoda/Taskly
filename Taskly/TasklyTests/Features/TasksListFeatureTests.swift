//
//  TasksListFeatureTests.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 27.04.2025.
//

import XCTest
import ComposableArchitecture
@testable import Taskly

@MainActor
final class TasksListFeatureTests: XCTestCase {
    func testAddNewTask() async {
        let store = TestStore(
            initialState: TasksListFeature.State(),
            reducer: { TasksListFeature() },
            withDependencies: { $0.uuid = .constant(UUID(0)) }
        )

        await store.send(.addButtonTapped) {
            $0.taskForm = TaskFormFeature.State()
        }
    }
    
    func testOpenTaskDetails() async {
        let store = TestStore(
            initialState: TasksListFeature.State(
                tasks: [TaskItem(id: UUID(0), title: "Test Task")]
            ),
            reducer: { TasksListFeature() },
            withDependencies: { $0.uuid = .constant(UUID(0)) }
        )
        let task = store.state.tasks[0]
        await store.send(.taskRow(id: task.id, action: .tapped)) {
			$0.taskForm = TaskFormFeature.State(task: task.asTaskItem)
        }
    }
    
    func testTaskRowTap() async {
        let task = TaskItem(id: UUID(0), title: "Test Task")
        let store = TestStore(
            initialState: TasksListFeature.State(tasks: [task]),
            reducer: { TasksListFeature() }
        )
        await store.send(.taskRow(id: task.id, action: .tapped)) {
            $0.taskForm = TaskFormFeature.State(task: task)
        }
    }
} 

//
//  Mocks.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 27.04.2025.
//

import Foundation
import ComposableArchitecture

extension TaskItem {
    /// A simple incomplete task
    static let mock = TaskItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        title: "Mock Task",
        isCompleted: false
    )
    /// A completed task
    static let completedMock = TaskItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        title: "Completed Mock Task",
        isCompleted: true
    )
    /// A task with a long title
    static let longTitleMock = TaskItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        title: "This is a very long mock task title for preview and test purposes",
        isCompleted: false
    )
    /// A task with special characters
    static let specialCharsMock = TaskItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        title: "Task with emoji 🚀🔥 and symbols #@!$%",
        isCompleted: false
    )
    /// Another completed task
    static let anotherCompletedMock = TaskItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        title: "Another Completed Task",
        isCompleted: true
    )
    /// A task with a short title
    static let shortTitleMock = TaskItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        title: "Short",
        isCompleted: false
    )
    /// All mocks for previews and tests
    static let allMocks: [TaskItem] = [
        .mock,
        .completedMock,
        .longTitleMock,
        .specialCharsMock,
        .anotherCompletedMock,
        .shortTitleMock
    ]
}

extension TasksListFeature.State {
    static let mock = TasksListFeature.State(
        tasks: TaskItem.allMocks
    )
}

extension StoreOf<TasksListFeature> {
    static let mock = Store(
        initialState: .mock
    ) {
        TasksListFeature()
    }
} 
//
//  AnalyticsClient.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import Foundation
import ComposableArchitecture

/// Represents an analytics event for task-related actions.
///
/// Usage example:
/// ```swift
/// // Log a task creation event
/// await analyticsClient.log(.taskCreated(id: task.id, title: task.title))
///
/// // Log a task completion event
/// await analyticsClient.log(.taskCompleted(id: task.id))
/// ```
enum AnalyticsEvent: Equatable, Codable {
    /// Event for when a new task is created.
    /// - Parameters:
    ///   - id: The unique identifier of the created task.
    ///   - title: The title of the created task.
    case taskCreated(id: TaskID, title: String)
    /// Event for when a task is marked as completed or uncompleted.
    /// - Parameters:
    ///   - id: The unique identifier of the task.
    ///   - isCompleted: The new completion status of the task.
    case taskCompleted(id: TaskID, isCompleted: Bool)
    /// Event for when a task is edited.
    /// - Parameters:
    ///   - id: The unique identifier of the edited task.
    ///   - newTitle: The new title of the task.
    case taskEdited(id: TaskID, newTitle: String)
    /// Event for when a task is deleted.
    /// - Parameter id: The unique identifier of the deleted task.
    case taskDeleted(id: TaskID)
    /// Event for when a batch of tasks is saved.
    /// - Parameter count: The number of saved tasks.
    case saveTasks(count: Int)
    // Add more cases as needed

    /// The name of the analytics event, used for logging or analytics systems.
    var name: String {
        switch self {
        case .taskCreated: return "task_created"
        case .taskCompleted: return "task_completed"
        case .taskEdited: return "task_edited"
        case .taskDeleted: return "task_deleted"
        case .saveTasks: return "save_tasks"
        }
    }

    private enum Key: String {
        case id = "id"
        case title = "title"
        case newTitle = "new_title"
        case count = "count"
        case isCompleted = "is_completed"
    }

    /// The parameters associated with the analytics event.
    var parameters: [String: String] {
        switch self {
        case let .taskCreated(id, title):
            return [Key.id.rawValue: id.uuidString, Key.title.rawValue: title]
        case let .taskCompleted(id, isCompleted):
            return [Key.id.rawValue: id.uuidString, Key.isCompleted.rawValue: String(isCompleted)]
        case let .taskEdited(id, newTitle):
            return [Key.id.rawValue: id.uuidString, Key.newTitle.rawValue: newTitle]
        case let .taskDeleted(id):
            return [Key.id.rawValue: id.uuidString]
        case let .saveTasks(count):
            return [Key.count.rawValue: String(count)]
        }
    }
}

// MARK: - Analytics Client
struct AnalyticsClient {
    public var log: @Sendable (_ event: AnalyticsEvent) async -> Void
    public var flush: @Sendable () async -> Void
}

// MARK: - Live Implementation
extension AnalyticsClient {
    static let live = AnalyticsClient(
        log: { event in
            await AnalyticsClientActor.shared.log(event)
        },
        flush: {
            await AnalyticsClientActor.shared.flush()
        }
    )
}

// MARK: - DependencyKey
private enum AnalyticsClientKey: DependencyKey {
    static let liveValue = AnalyticsClient.live
}

extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClientKey.self] }
        set { self[AnalyticsClientKey.self] = newValue }
    }
}

// MARK: - batching & debouncing
actor AnalyticsClientActor {
    static let shared = AnalyticsClientActor()
    private var events: [AnalyticsEvent] = []
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 3

    func log(_ event: AnalyticsEvent) async {
        events.append(event)
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
			let interval = self?.debounceInterval ?? 0
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            await self?.flush()
        }
    }

    func flush() async {
        guard !events.isEmpty else { return }
        for event in events {
            print("[Analytics] Event: \(event.name), parameters: \(event.parameters)")
        }
        events.removeAll()
    }
} 

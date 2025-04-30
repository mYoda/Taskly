//
//  SyncClient.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import Foundation
import ComposableArchitecture

struct SyncClient {
    var syncTasks: @Sendable ([TaskItem]) async throws -> Void
    var loadTasks: @Sendable () async throws -> [TaskItem]
}

extension SyncClient {
    static func live(fileClient: FileClient) -> SyncClient {
        // Debouncing via actor
        let debounceInterval: TimeInterval = 0.0 // 0 seconds
        actor Debouncer {
            private var currentTask: Task<Void, Error>?
            func debounce(for interval: TimeInterval, operation: @escaping () async throws -> Void) async throws {
                currentTask?.cancel()
                let task = Task {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    try await operation()
                }
                currentTask = task
                try await task.value
            }
        }
        let debouncer = Debouncer()
        return SyncClient(
            syncTasks: { tasks in
                try await debouncer.debounce(for: debounceInterval) {
                    // Artificial delay
                    try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
                    // Random error (20% chance)
                    if Int.random(in: 1...5) == 1 {
                        throw NSError(domain: "Sync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sync error"])
                    }
                    try await fileClient.saveTasks(tasks)
                }
            },
            loadTasks: {
                try await fileClient.loadTasks()
            }
        )
    }
} 


private enum SyncClientKey: DependencyKey {
	static let liveValue = SyncClient.live(fileClient: .live)
}

extension DependencyValues {
	var syncClient: SyncClient {
		get { self[SyncClientKey.self] }
		set { self[SyncClientKey.self] = newValue }
	}
}

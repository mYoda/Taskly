//
//  FileClient.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import Foundation
import ComposableArchitecture

// MARK: - FileClient

struct FileClient {
	var load: @Sendable (_ path: String) async throws -> Data
	var save: @Sendable (_ data: Data, _ path: String) async throws -> Void
	var delete: @Sendable (_ path: String) async throws -> Void

	func decode<T: Decodable>(_ type: T.Type, from path: String) async throws -> T {
		let data = try await load(path)
		return try JSONDecoder().decode(T.self, from: data)
	}

	func encode<T: Encodable>(_ value: T, to path: String) async throws {
		let data = try JSONEncoder().encode(value)
		try await save(data, path)
	}
}

// MARK: - Live Implementation

extension FileClient {
	static let live = FileClient(
		load: { path in
			let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
				.appendingPathComponent(path)
			return try Data(contentsOf: url)
		},
		save: { data, path in
			let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
				.appendingPathComponent(path)
			try data.write(to: url, options: [.atomic])
		},
		delete: { path in
			let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
				.appendingPathComponent(path)
			try FileManager.default.removeItem(at: url)
		}
	)
}

// MARK: - TCA

private enum FileClientKey: DependencyKey {
	static let liveValue = FileClient.live
}
extension DependencyValues {
	var fileClient: FileClient {
		get { self[FileClientKey.self] }
		set { self[FileClientKey.self] = newValue }
	}
}

// MARK: - Tasks

extension FileClient {

	private var tasksFileName: String { "tasks.json" }

	func saveTasks(_ tasks: [TaskItem]) async throws {
		try await encode(tasks, to: tasksFileName)
	}

	func loadTasks() async throws -> [TaskItem] {
		do {
			return try await decode([TaskItem].self, from: tasksFileName)
		} catch {
			if (error as NSError).domain == NSCocoaErrorDomain,
			   (error as NSError).code == NSFileReadNoSuchFileError {
				return []
			} else {
				throw error
			}
		}
	}

	func deleteTasks() async throws {
		try await delete(tasksFileName)
	}
}

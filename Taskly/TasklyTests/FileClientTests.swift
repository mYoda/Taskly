//
//  FileClientTests.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import XCTest
import Dependencies
@testable import Taskly

final class FileClientTests: XCTestCase {
    func testSaveAndLoadTasks_Success() async throws {
        let savedData = LockIsolated<Data?>(nil)
        let fileClient = FileClient(
            load: { _ in savedData.value ?? Data() },
            save: { data, _ in savedData.setValue(data) },
            delete: { _ in savedData.setValue(nil) }
        )
        let tasks = [TaskItem(id: UUID(0), title: "Test")]
        try await fileClient.saveTasks(tasks)
        let loadedTasks = try await fileClient.loadTasks()
        XCTAssertEqual(loadedTasks, tasks)
    }

    func testLoadTasks_FileNotFound_ReturnsEmpty() async throws {
        let fileClient = FileClient(
            load: { _ in throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError) },
            save: { _, _ in },
            delete: { _ in }
        )
        let loadedTasks = try await fileClient.loadTasks()
        XCTAssertEqual(loadedTasks, [])
    }

	func testLoadTasks_ThrowsOtherError() async {
		let fileClient = FileClient(
			load: { _ in throw NSError(domain: "Test", code: 123) },
			save: { _, _ in },
			delete: { _ in }
		)
		do {
			_ = try await fileClient.loadTasks()
			XCTFail("Expected error, but got success")
		} catch {
			// Success: error was thrown
		}
	}

    func testDeleteTasks() async throws {
        let deleted = LockIsolated(false)
        let fileClient = FileClient(
            load: { _ in Data() },
            save: { _, _ in },
            delete: { _ in deleted.setValue(true) }
        )
        try await fileClient.deleteTasks()
        XCTAssertTrue(deleted.value)
    }

    func testEncodeDecodeTasks() async throws {
        let fileClient = FileClient(
            load: { _ in
                let tasks = [TaskItem(id: UUID(0), title: "Test")]
                return try! JSONEncoder().encode(tasks)
            },
            save: { _, _ in },
            delete: { _ in }
        )
        let loadedTasks = try await fileClient.loadTasks()
        XCTAssertEqual(loadedTasks, [TaskItem(id: UUID(0), title: "Test")])
    }
}

// MARK: - Helpers

func XCTAssertThrowsErrorAsync(
    _ expression: () async throws -> Void,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected error, but got success", file: file, line: line)
    } catch { }
} 

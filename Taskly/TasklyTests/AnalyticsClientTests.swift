//
//  AnalyticsClientTests.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import XCTest
import ComposableArchitecture
@testable import Taskly

@MainActor
final class AnalyticsClientTests: XCTestCase {
    func testLogAndFlush() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let testClient = AnalyticsClient(
            log: { event in events.withValue { $0.append(event) } },
            flush: { }
        )

		await withDependencies {
			$0.analyticsClient = testClient
			$0.uuid = .incrementing
		} operation: {
			await testClient.log(.taskCreated(id: UUID(0), title: "Test"))
			await testClient.log(.taskCompleted(id: UUID(1), isCompleted: true))
		}

        let logged = events.value
        XCTAssertEqual(logged.count, 2)
        if case let .taskCreated(id, title) = logged[0] {
            XCTAssertEqual(id, UUID(0))
            XCTAssertEqual(title, "Test")
        } else {
            XCTFail("First event is not .taskCreated")
        }
        if case let .taskCompleted(id, isCompleted) = logged[1] {
            XCTAssertEqual(id, UUID(1))
            XCTAssertTrue(isCompleted)
        } else {
            XCTFail("Second event is not .taskCompleted")
        }
    }

    func testDebounceBatching() async throws {
        let expectation = expectation(description: "Debounced flush")
        let events = LockIsolated<[AnalyticsEvent]>([])
        var flushed = false
        let testClient = AnalyticsClient(
            log: { event in events.withValue { $0.append(event) } },
            flush: {
                flushed = true
                expectation.fulfill()
            }
        )

		await withDependencies {
			$0.analyticsClient = testClient
			$0.uuid = .incrementing
		} operation: {
			await testClient.log(.taskCreated(id: UUID(0), title: "A"))
			await testClient.log(.taskCreated(id: UUID(1), title: "B"))
			do {
				try await Task.sleep(nanoseconds: 100_000_000)
			} catch {
				XCTFail("Sleep threw an error: \(error)")
			}
			await testClient.flush()
		}
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(flushed)
        XCTAssertEqual(events.value.count, 2)
    }

    func testEventParameters() async {
        let id = UUID(3)
        let event = AnalyticsEvent.taskCompleted(id: id, isCompleted: false)
        let params = event.parameters
        XCTAssertEqual(params["id"], id.uuidString)
        XCTAssertEqual(params["is_completed"], "false")
    }
} 

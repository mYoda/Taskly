//
//  TasklyApp.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - App

@main
struct TasklyApp: App {
    static let store = Store(
        initialState: TasksListFeature.State(
			tasks: []
        )
    ) {
        TasksListFeature()
//            ._printChanges()
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Dependency(\.analyticsClient) var analyticsClient

    var body: some Scene {
        WindowGroup {
            NavigationStack {
//				TasksListView(store: Self.store)
                TaskListView(store: Self.store)
            }
            .onChange(of: scenePhase) {
                if scenePhase == .background {
                    Task {
                        await analyticsClient.flush()
                    }
                }
            }
        }
    }
}

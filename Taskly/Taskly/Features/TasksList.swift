//
//  TasksList.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 28.04.2025.
//

import SwiftUI
import ComposableArchitecture
import IdentifiedCollections


// MARK: - Feature
struct TasksListFeature: Reducer {
	struct State: Equatable {
		@PresentationState var taskForm: TaskFormFeature.State?
		var tasks: IdentifiedArrayOf<TaskRowFeature.State>
		var isSyncing: Bool = false
		var syncError: String? = nil

		init(tasks: [TaskItem] = []) {
			self.tasks = IdentifiedArrayOf(
				uniqueElements: tasks.map {
					TaskRowFeature.State(
						id: $0.id,
						title: $0.title,
						isCompleted: $0.isCompleted)
				}
			)
		}
	}

	enum Action {
		case loadTasks
		case saveTasks([TaskItem])
		case tasksLoaded(Result<[TaskItem], Error>)
		case syncStarted
		case syncFinished(Result<Void, Error>)
		case retrySync
		case taskForm(PresentationAction<TaskFormFeature.Action>)
		case addButtonTapped
		case deleteTask(TaskItem)
		case addNewTask(title: String)
		case taskRow(id: UUID, action: TaskRowFeature.Action)
	}

	@Dependency(\.syncClient) var syncClient
	@Dependency(\.analyticsClient) var analyticsClient
	@Dependency(\.uuid) var uuid

	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
				case .syncStarted:
					state.isSyncing = true
					state.syncError = nil
					return .none

				case .loadTasks:
					return .concatenate(
						.send(.syncStarted),
						.run { send in
							do {
								let tasks = try await syncClient.loadTasks()
								await send(.tasksLoaded(.success(tasks)))
							} catch {
								await send(.tasksLoaded(.failure(error)))
							}
						}
					)

				case let .saveTasks(tasks):
					return .concatenate(
						.send(.syncStarted),
						.run { send in
							do {
								try await syncClient.syncTasks(tasks)
								await send(.syncFinished(.success(())))
							} catch {
								await send(.syncFinished(.failure(error)))
							}
							await analyticsClient.log(.saveTasks(count: tasks.count))
						}
					)

				case let .tasksLoaded(.success(tasks)):
					state.tasks = IdentifiedArrayOf(uniqueElements: tasks.asTaskRowStates)
					state.isSyncing = false
					state.syncError = nil
					return .none

				case .tasksLoaded(.failure(let error)):
					state.isSyncing = false
					state.syncError = error.localizedDescription
					return .none

				case .syncFinished(let result):
					state.isSyncing = false
					switch result {
					case .success:
						state.syncError = nil
					case .failure(let error):
						state.syncError = error.localizedDescription
					}
					return .none

				case .retrySync:
					return .send(.saveTasks(state.tasks.asTaskItems))

				case .addButtonTapped:
					state.taskForm = TaskFormFeature.State()
					return .none

				case let .taskRow(id, rowAction):
					return handleTaskRowAction(&state, id: id, action: rowAction)

				case .taskForm(.presented(.saveTask(let task))):
					if let index = state.tasks.firstIndex(where: { $0.id == task.id }) {
						state.tasks[index].title = task.title
						state.tasks[index].isCompleted = task.isCompleted
					} else {
						state.tasks.insert(task.asTaskRowState, at: 0)
					}
					moveTaskIfNeeded(tasks: &state.tasks, toggledTask: task)
					return .send(.saveTasks(state.tasks.asTaskItems))

				case .taskForm:
					return .none

				case .deleteTask(let task):
					state.tasks.removeAll { $0.id == task.id }
					return .merge(
						.send(.saveTasks(state.tasks.asTaskItems)),
						.run { _ in
							await analyticsClient.log(.taskDeleted(id: task.id))
						}
					)

				case let .addNewTask(title):
					let newTask = TaskItem(id: uuid(), title: title)
					state.tasks.insert(newTask.asTaskRowState, at: 0)
					return .send(.saveTasks(state.tasks.asTaskItems))
			}
		}
		.forEach(\.tasks, action: /Action.taskRow) {
			TaskRowFeature()
		}
		.ifLet(\.$taskForm, action: /Action.taskForm) {
			TaskFormFeature()
		}
	}

	private func handleTaskRowAction(
		_ state: inout State,
		id: UUID,
		action: TaskRowFeature.Action
	) -> Effect<Action> {
		switch action {
			case .tapped:
				if let taskRowState = state.tasks[id: id] {
					state.taskForm = TaskFormFeature.State(
						task: taskRowState.asTaskItem
					)
				}
				return .none
			case .toggleCompleted:
				if let index = state.tasks.firstIndex(where: { $0.id == id }) {
					let changedTask = state.tasks[index].asTaskItem
					moveTaskIfNeeded(tasks: &state.tasks, toggledTask: changedTask)
				}
				return .send(.saveTasks(state.tasks.asTaskItems))
		}
	}

	// for animation
	private func moveTaskIfNeeded(
		tasks: inout IdentifiedArrayOf<TaskRowFeature.State>,
		toggledTask: TaskItem
	) {
		guard let index = tasks.firstIndex(where: { $0.id == toggledTask.id }) else { return }
		let taskState = tasks.remove(at: index)
		if toggledTask.isCompleted {
			tasks.append(taskState)
		} else {
			tasks.insert(taskState, at: 0)
		}
	}
}


// MARK: - Mapping
extension TaskRowFeature.State {
	init(_ item: TaskItem) {
		self.init(id: item.id, title: item.title, isCompleted: item.isCompleted)
	}
	var asTaskItem: TaskItem {
		TaskItem(id: id, title: title, isCompleted: isCompleted)
	}
}

private extension TaskItem {
	var asTaskRowState: TaskRowFeature.State {
		TaskRowFeature.State(self)
	}
}

private extension Array where Element == TaskItem {
	var asTaskRowStates: [TaskRowFeature.State] {
		self.map { TaskRowFeature.State($0) }
	}
}

private extension Array where Element == TaskRowFeature.State {
	var asTaskItems: [TaskItem] {
		self.map { $0.asTaskItem }
	}
}

private extension IdentifiedArrayOf where Element == TaskRowFeature.State {
	var asTaskItems: [TaskItem] {
		self.map { $0.asTaskItem }
	}
}

//
//  TaskForm.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 27.04.2025.
//

import SwiftUI
import ComposableArchitecture

struct TaskFormFeature: Reducer {

	enum Field: Hashable {
		case title
	}

	struct State: Equatable {
		@BindingState var focus: Field?
		@BindingState var task: TaskItem
		var syncError: String?
		let isNewTask: Bool
		let originalTask: TaskItem

		init(focus: Field? = .title, task: TaskItem? = nil) {
			self.focus = focus
			@Dependency(\.uuid) var uuid
			let initialTask = task ?? TaskItem(id: uuid())
			self.task = initialTask
			self.originalTask = initialTask
			self.syncError = nil
			self.isNewTask = task == nil ? true : false
		}
	}

	enum Action: BindableAction {
		case binding(BindingAction<State>)
		case saveButtonTapped
		case cancelButtonTapped
		case saveTask(TaskItem)
	}
	@Dependency(\.uuid) var uuid
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.analyticsClient) var analyticsClient

	var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
				case .binding:
					let statusChanged = state.originalTask.isCompleted != state.task.isCompleted
					if statusChanged {
						return .run { [task = state.task] _ in
							await analyticsClient.log(.taskCompleted(id: task.id, isCompleted: task.isCompleted))
						}
					}
					return .none

				case .saveButtonTapped:
					return .run { [isNew = state.isNewTask, task = state.task, originalTitle = state.originalTask.title] send in
						if isNew {
							await analyticsClient.log(.taskCreated(id: task.id, title: task.title))
						} else if task.title != originalTitle {
							await analyticsClient.log(.taskEdited(id: task.id, newTitle: task.title))
						}
						await send(.saveTask(task))
						await dismiss()
					}

				case .cancelButtonTapped:
					return .run { _ in await self.dismiss() }

				case .saveTask:
					return .none
			}
		}
	}
}

struct TaskFormView: View {
	let store: StoreOf<TaskFormFeature>
	@FocusState private var focusedField: TaskFormFeature.Field?

	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			NavigationStack {
				ScrollView {
					VStack(spacing: 0) {
						Spacer().frame(height: Theme.topSpacing)
						
						VStack(spacing: Theme.fieldSpacing) {
							TextField(Theme.titlePlaceholder, text: viewStore.$task.title)
								.focused($focusedField, equals: .title)
								.padding()
								.background(
									RoundedRectangle(cornerRadius: Theme.fieldCornerRadius)
										.fill(Theme.fieldBackground)
								)
							
							Toggle(Theme.completedLabel, isOn: viewStore.$task.isCompleted)
								.padding(.horizontal)
								.tint(Theme.toggleTint)
						}
						.padding()
					}
				}
				.background(Theme.background)

				.navigationTitle(Theme.navigationTitle)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button(Theme.cancelButton) {
							viewStore.send(.cancelButtonTapped)
						}
					}
					ToolbarItem(placement: .confirmationAction) {
						Button(Theme.saveButton) {
							viewStore.send(.saveButtonTapped)
						}
					}
				}
				.bind(viewStore.$focus, to: self.$focusedField)
			}
		}
	}
}

// MARK: - Theme
extension TaskFormView {
	enum Theme {
		/// "Title"
		static let titlePlaceholder = "Title"
		/// "Completed"
		static let completedLabel = "Completed"
		/// "Edit Task"
		static let navigationTitle = "Edit Task"
		/// "Cancel"
		static let cancelButton = "Cancel"
		/// "Save"
		static let saveButton = "Save"
		/// 20
		static let topSpacing: CGFloat = 20
		/// 16
		static let fieldSpacing: CGFloat = 16
		/// 10
		static let fieldCornerRadius: CGFloat = 10
		/// Color.white
		static let fieldBackground = Color.white
		/// Color.accentColor
		static let toggleTint = Color.accentColor
		/// Color(uiColor: .systemGroupedBackground)
		static let background = Color(uiColor: .systemGroupedBackground)
	}
}

#if DEBUG
#Preview("New Task") {
	TaskFormView(
		store: Store(
			initialState: TaskFormFeature.State(),
			reducer: { TaskFormFeature() }
		)
	)
}

#Preview("Edit Task") {
	TaskFormView(
		store: Store(
			initialState: TaskFormFeature.State(
				task: TaskItem(
					id: UUID(0),
					title: "Existing Task",
					isCompleted: true
				)
			),
			reducer: { TaskFormFeature() }
		)
	)
}
#endif

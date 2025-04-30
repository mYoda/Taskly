//
//  TaskListView.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 29.04.25.
//

import Foundation
import SwiftUI
import ComposableArchitecture

private enum GeometryId: StringLiteralType {
	case inputButton
	case background
	case title
	case date

	var id: String { rawValue }
}

struct TaskListView: View {
	let store: StoreOf<TasksListFeature>
	@Namespace private var namespace
	@State private var inputText: String = ""
	@State private var inputStyle: InputArea.InputButtonStyle = .start

	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			NavigationStack {
				GeometryReader { geometry in
					ZStack {

						backgroundView(height: geometry.size.height, isEmpty: viewStore.tasks.isEmpty)

						Group {
							if viewStore.tasks.isEmpty {
								emptyStateSection(height: geometry.size.height)
							} else {
								taskListSection
							}
						}
					}
				}
				.ignoresSafeArea()
				.edgesIgnoringSafeArea(.all)
				.toolbar(.hidden, for: .navigationBar)
				.animation(.easeInOut(duration: 0.6), value: inputStyle)
				.onAppear {
					viewStore.send(.loadTasks)
					if !viewStore.tasks.isEmpty {
						inputStyle = .edit
					}
				}
				.onChange(of: viewStore.tasks) {
					if !viewStore.tasks.isEmpty {
						inputStyle = .edit
					} else {
						inputStyle = .start
					}
				}
				.sheet(
					store: store.scope(
						state: \.$taskForm,
						action: { .taskForm($0) }
					)
				) { store in
					TaskFormView(store: store)
				}
			}
		}
	}
}

// MARK: - Subviews
extension TaskListView {

	@ViewBuilder
	private func backgroundView(height: CGFloat, isEmpty: Bool) -> some View {
		VStack(spacing: 0) {
			Spacer()

			ZStack {
				Theme.backgroundGrayColor

				if isEmpty {
					VStack(spacing: Theme.smallSpacing) {
						Text(Theme.descriptionTitle)
						Text(Theme.descriptionSubtitle)
					}
					.font(Theme.smallFont)
					.multilineTextAlignment(.center)
					.foregroundStyle(Theme.textColor)
					.transition(
						.move(edge: .bottom)
						.combined(with: .opacity)
					)
				}
			}
			.frame(height: isEmpty ? height * 0.5 : .zero)
		}
	}

	@ViewBuilder
	private func emptyStateSection(height: CGFloat) -> some View {
		ZStack {
			VStack {
				headerSection()
					.frame(height: height * 0.5)
				Spacer()
			}
			inputArea
				.matchedGeometryEffect(id: GeometryId.inputButton.id, in: namespace)
		}
	}

	private var taskListSection: some View {
		VStack(alignment: .leading, spacing: .zero) {
			ZStack(alignment: .trailing) {
				headerSection(alignment: .leading, spacing: Theme.hugeSpacing)

				AnimatedDividerView(
					color: inputStyle == .active ? Theme.dividerGrayColor : Theme.dividerBlackColor,
					lineWidth: Theme.dividerLineWidth
				)
				.offset(y: Theme.offset)

				inputArea
					.matchedGeometryEffect(id: GeometryId.inputButton.rawValue, in: namespace)
					.offset(y: Theme.offset)
			}
			.padding(.top, Theme.headerTopPadding)

			TaskListContainer(store: store)

			Spacer()
		}
		.animation(.easeInOut(duration: 0.6), value: inputStyle)
	}

	private func headerSection(alignment: HorizontalAlignment = .center, spacing: CGFloat = Theme.smallSpacing) -> some View {
		
		VStack(alignment: alignment, spacing: spacing) {
			HStack {
				Spacer ()
				Text(Theme.taskly)
					.font(Theme.heavyFont)
					.matchedGeometryEffect(id: GeometryId.title.id, in: namespace)
				Spacer ()
			}
			
			Text(Theme.today)
				.font(Theme.smallFont)
				.foregroundStyle(Theme.textColor)
				.frame(height: Theme.dateHeight)
				.matchedGeometryEffect(id: GeometryId.date.id, in: namespace)
		}
		.padding(.horizontal, Theme.contentPadding)
		.padding(.vertical, Theme.verticalSpacing)
		
	}

	private var inputArea: some View {
		InputArea(
			text: $inputText,
			style: $inputStyle,
			onTapGesture: { inputStyle = .active },
			onEditingChanged: { _ in },
			onSubmit: addTask
		)
		.padding(.horizontal, Theme.contentPadding)
	}

	private var descriptionView: some View {
		VStack(spacing: Theme.smallSpacing) {
			Text(Theme.descriptionTitle)
			Text(Theme.descriptionSubtitle)
		}
		.font(Theme.smallFont)
		.multilineTextAlignment(.center)
		.foregroundStyle(Theme.textColor)
	}
}

// MARK: - Actions
extension TaskListView {
	private func addTask() {
		guard
			!inputText
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.isEmpty else { return }
		let newText = inputText
		inputText = ""
		Task {
			try? await Task.sleep(for: .seconds(1))
			store.send(.addNewTask(title: newText))

			inputStyle = .edit
		}
		withAnimation(.easeInOut(duration: 1)) {
			inputStyle = .completed
		}
	}
}

struct TaskListContainer: View {
	let store: StoreOf<TasksListFeature>

	var body: some View {
		WithViewStore(store, observe: { $0.tasks }) { storeTasks in
			List {
				ForEachStore(
					store.scope(state: \.tasks, action: TasksListFeature.Action.taskRow(id:action:))
				) { rowStore in
					TaskRow(store: rowStore)
						.transition(.asymmetric(
							insertion: .scale(scale: TaskListView.Theme.taskInsertionScale).combined(with: .opacity),
							removal: .move(edge: .top).combined(with: .opacity)
						))
						.listRowBackground(Color.clear)
						.listRowSeparator(.hidden)
						.listRowSpacing(.zero)
						.padding(.horizontal, TaskListView.Theme.listRowPadding)
				}
				.onDelete { indexSet in
					for index in indexSet {
						let task = storeTasks.state[index]
						_ = withAnimation(.easeInOut(duration: 0.6)) {
							store.send(.deleteTask(TaskItem(
								id: task.id,
								title: task.title,
								isCompleted: task.isCompleted
							)))
						}
					}
				}
			}
			.listStyle(.plain)
			.animation(.default, value: storeTasks.state)
		}
	}
}

// MARK: - Theme
private extension TaskListView {
	enum Theme {
		// Layout
		/// 36
		static let contentPadding: CGFloat = 36
		/// 18
		static let verticalSpacing: CGFloat = 18
		/// 1
		static let dividerHeight: CGFloat = 1
		/// 8
		static let smallSpacing: CGFloat = 8
		/// 12
		static let listRowPadding: CGFloat = 12
		/// 32
		static let dateHeight: CGFloat = 32
		/// 80
		static let headerTopPadding: CGFloat = 80
		/// 72
		static let hugeSpacing: CGFloat = 72
		/// 6
		static let offset: CGFloat = 6
		/// 1
		static let dividerLineWidth: CGFloat = 1

		// Colors
		/// .gray.opacity(0.1)
		static let backgroundGrayColor: Color = .gray.opacity(0.1)
		/// .black
		static let dividerBlackColor: Color = .black
		/// .gray.opacity(0.2)
		static let dividerGrayColor: Color = .gray.opacity(0.2)
		/// .gray.opacity(0.2)
		static let taskBorderColor: Color = .gray.opacity(0.2)
		/// .black
		static let taskCompletedColor: Color = .black
		/// .gray.opacity(0.8)
		static let textColor: Color = .gray.opacity(0.8)

		// Texts
		/// "Tasks"
		static let navigationTitle: String = "Tasks"
		/// "Taskly"
		static let taskly: String = "Taskly"
		/// "Monday 28 Apr 2025"
		static let todoDate: String = "Monday 28 Apr 2025"
		/// "What do you want to do today?"
		static let descriptionTitle: String = "What do you want to do today?"
		/// "Start adding items to your tasks list."
		static let descriptionSubtitle: String = "Start adding items to your tasks list."

		// Animations
		/// 0.8
		static let taskInsertionScale: CGFloat = 0.8

		// Fonts
		/// .system(size: 16, weight: .regular)
		static let smallFont: Font = .system(size: 16, weight: .regular)
		/// .system(size: 32, weight: .heavy)
		static let heavyFont: Font = .system(size: 32, weight: .heavy)

		/// DateFormatter for today string
		private static let dateFormatter: DateFormatter = {
			let formatter = DateFormatter()
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.dateFormat = "EEEE dd MMM yyyy"
			return formatter
		}()
		/// today string
		static var today: String {
			dateFormatter.string(from: Date())
		}
	}
}

#if DEBUG
import ComposableArchitecture

#Preview {
	TaskListView(
		store: Store(
			initialState: TasksListFeature.State(
				tasks: []// TaskItem.allMocks
			)
		) {
			TasksListFeature()
		} withDependencies: {
			$0.syncClient = SyncClient(
				syncTasks: { _ in },
//				loadTasks: { TaskItem.allMocks }
								loadTasks: { [] }
			)
		}
	)
}
#endif

import ComposableArchitecture
import Foundation
import SwiftUI

struct TaskRowFeature: Reducer {
	struct State: Equatable, Identifiable {
		let id: UUID
		var title: String
		var isCompleted: Bool
	}
	
	enum Action: Equatable {
		case toggleCompleted
		case tapped
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
				case .toggleCompleted:
					state.isCompleted.toggle()
					return .none
				case .tapped:
					return .none
			}
		}
	}
}

struct TaskRow: View {
	let store: StoreOf<TaskRowFeature>
	
	@State private var gradientOffset: CGFloat = TaskRow.Theme.initialGradientOffset
	@State private var scale: CGFloat = TaskRow.Theme.defaultButtonScale
	
	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			HStack(spacing: TaskRow.Theme.hStackSpacing) {
				toggleButton(
					isDone: viewStore.isCompleted,
					action: {
						withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
							scale = TaskRow.Theme.pulseExpandedScale
						}
						Task {
							try? await Task.sleep(for: .milliseconds(200)) // 0.2 seconds
							withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
								scale = TaskRow.Theme.defaultButtonScale
							}
						}
						viewStore.send(.toggleCompleted)
					}
				)
				titleWithUnderline(
					title: viewStore.title,
					isDone: viewStore.isCompleted
				)
				.onTapGesture {
					viewStore.send(.tapped)
				}
			}
			.onAppear {
				gradientOffset = viewStore.isCompleted
				? TaskRow.Theme.completedGradientOffset
				: TaskRow.Theme.initialGradientOffset
			}
			.onChange(of: viewStore.isCompleted) {
				withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
					gradientOffset = viewStore.isCompleted
					? TaskRow.Theme.completedGradientOffset
					: TaskRow.Theme.initialGradientOffset
				}
			}
		}
	}
	
	private func toggleButton(isDone: Bool, action: @escaping () -> Void) -> some View {
		ZStack {
			Circle()
				.fill(isDone ? TaskRow.Theme.completedTitleColor : .white)
				.padding(TaskRow.Theme.circlePadding)
				.scaleEffect(scale)
			
			Circle()
				.strokeBorder(isDone ? TaskRow.Theme.completedTitleColor : TaskRow.Theme.borderColor, lineWidth: isDone ? TaskRow.Theme.completedBorderWidth : TaskRow.Theme.defaultBorderWidth)
				.padding(isDone ? 0 : TaskRow.Theme.circlePadding)
				.opacity(isDone ? 0 : 1)
				.animation(.spring(response: 0.1, dampingFraction: 0.3), value: isDone)
			
			if isDone {
				CheckmarkView(size: Theme.checkmarkSize)
					.padding(Theme.checkmarkPadding)
					.scaleEffect(scale)
					.transition(.scale(scale: 0.5, anchor: .center).combined(with: .opacity))
			}
		}
		.frame(width: TaskRow.Theme.circleSize.width, height: TaskRow.Theme.circleSize.height)
		.animation(.spring(response: 0.4, dampingFraction: 0.5), value: isDone)
		.onTapGesture(perform: action)
	}
	
	private func titleWithUnderline(title: String, isDone: Bool) -> some View {
		ZStack(alignment: .leading) {
			Theme.backgroundColor
			HStack {
				Text(title)
					.lineLimit(1)
					.font(.headline)
					.fontWeight(.regular)
				Spacer()
			}
			.foregroundStyle(gradient)
			.animation(.spring(duration: 0.5).delay(0.2), value: isDone)
			
			Rectangle()
				.fill(isDone ? TaskRow.Theme.activeTitleColor : TaskRow.Theme.completedTitleColor)
				.frame(height: TaskRow.Theme.lineHeight)
				.frame(maxWidth: isDone ? .infinity : .zero)
				.animation(.spring(duration: 0.8).delay(0.2), value: isDone)
		}
	}
	
	private var gradient: LinearGradient {
		LinearGradient(
			colors: [
				TaskRow.Theme.activeTitleColor,
				TaskRow.Theme.completedTitleColor
			],
			startPoint: UnitPoint(x: gradientOffset + 1, y: 0),
			endPoint: UnitPoint(x: gradientOffset - 1, y: 0)
		)
	}
}

// MARK: - Theme
extension TaskRow {
	enum Theme {
		// Layout
		/// CGSize(width: 40, height: 40)
		static let circleSize = CGSize(width: 40, height: 40)
		/// CGSize(width: 20, height: 20)
		static let checkmarkSize = CGSize(width: 20, height: 20)
		/// 20
		static let hStackSpacing: CGFloat = 20
		/// 5
		static let circlePadding: CGFloat = 5
		/// 10
		static let checkmarkPadding: CGFloat = 10
		
		// Borders
		/// 1
		static let defaultBorderWidth: CGFloat = 1
		/// 5
		static let completedBorderWidth: CGFloat = 5
		
		// Lines
		/// 1
		static let lineHeight: CGFloat = 1
		
		// Gradient
		/// 2
		static let initialGradientOffset: CGFloat = 2
		/// -2
		static let completedGradientOffset: CGFloat = -2
		
		// Scale
		/// 1
		static let defaultButtonScale: CGFloat = 1
		/// 1.2
		static let pulseExpandedScale: CGFloat = 1.2
		
		// Colors
		/// .gray.opacity(0.2)
		static let activeTitleColor: Color = .gray.opacity(0.2)
		/// .black
		static let completedTitleColor: Color = .black
		/// .gray.opacity(0.2)
		static let borderColor: Color = .gray.opacity(0.2)
		/// .white
		static let backgroundColor: Color = .white
	}
}

// MARK: - Preview
#if DEBUG
struct TaskRow_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 20) {
			TaskRow(
				store: Store(
					initialState: TaskRowFeature.State(
						id: UUID(),
						title: "Active task",
						isCompleted: false
					),
					reducer: { TaskRowFeature() }
				)
			)
			TaskRow(
				store: Store(
					initialState: TaskRowFeature.State(
						id: UUID(),
						title: "Completed task",
						isCompleted: true
					),
					reducer: { TaskRowFeature() }
				)
			)
		}
		.padding()
		.previewLayout(.sizeThatFits)
	}
}
#endif

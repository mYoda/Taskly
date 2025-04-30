//
//  InputArea.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 29.04.25.
//

import Foundation
import SwiftUI



public struct InputArea: View {
	@Binding var text: String
	@Binding var style: InputButtonStyle
	
	let onTapGesture: () -> Void
	let onEditingChanged: (Bool) -> Void
	let onSubmit: () -> Void
	private var isCheckmarkShown:  Bool  { style == .completed }
	
	init(
		text: Binding<String>,
		style: Binding<InputButtonStyle>,
		onTapGesture: @escaping () -> Void,
		onEditingChanged: @escaping (Bool) -> Void = {_ in },
		onSubmit: @escaping () -> Void
	) {
		self._text = text
		self._style = style
		self.onTapGesture = onTapGesture
		self.onEditingChanged = onEditingChanged
		self.onSubmit = onSubmit
	}
	
	public var body: some View {
		ZStack {
			background
				.contentShape(Rectangle())
			
			inputField
		}
		.frame(height: Theme.height)
		.frame(maxWidth: style.maxWidth)
	}
	
	private var background: some View {
		RoundedRectangle(cornerRadius: Theme.cornerRadius)
			.fill(style.backgroundColor)
			.overlay(
				RoundedRectangle(cornerRadius: Theme.cornerRadius)
					.stroke(
						style.strokeColor,
						lineWidth: Theme.borderWidth
					)
			)
	}
	
	private var inputField: some View {
		HStack(spacing: Theme.hStackSpacing) {
			if style == .active {
				FocusInputField(
					text: $text,
					tintColor: Theme.textFieldTintColor,
					onEditingChanged: onEditingChanged,
					onSubmit: onSubmit
				)
				.transition(.opacity)
			}

			Button(
				action: {
					if style == .active {
						onSubmit()
					} else {
						onTapGesture()
					}
				}, label: {
					HStack(spacing: Theme.hStackSpacing) {
						PlusToCheckmarkView(
							isCheckmarkShown: isCheckmarkShown,
							color: style.tintColor,
							lineWidth: Theme.checkmarkLineWidth,
							size: Theme.checkmarkSize
						)
						
						if style == .start {
							Text(Theme.placeholder)
								.foregroundColor(Theme.placeholderColor)
								.transition(.opacity)
						}
					}
				})
		}
		.padding(.horizontal, Theme.hStackPadding)
	}
}


// MARK: - FocusInputField
private struct FocusInputField: View {
	@FocusState private var isFocused: Bool
	@Binding var text: String
	@State private var isVisibleKey: Bool = true
	
	let tintColor: Color
	let onEditingChanged: (Bool) -> Void
	let onSubmit: () -> Void
	
	var body: some View {
		TextField("", text: $text, onEditingChanged: onEditingChanged)
			.multilineTextAlignment(.leading)
			.focused($isFocused)
			.tint(tintColor)
			.submitLabel(.done)
			.onSubmit { onSubmit() }
			.task(id: isVisibleKey) {
				if isVisibleKey {
					try? await Task.sleep(for: .milliseconds(600))
					isFocused = true
				}
			}
	}
}

// MARK: - Theme

private extension InputArea {
	enum Theme {
		// Layout
		/// 36
		static let cornerRadius: CGFloat = 36
		/// 1
		static let borderWidth: CGFloat = 1
		/// 72
		static let height: CGFloat = 72
		/// 30
		static let activePadding: CGFloat = 30
		/// 100
		static let inactivePadding: CGFloat = 100
		/// 20
		static let hStackSpacing: CGFloat = 20
		/// 30
		static let hStackPadding: CGFloat = 30
		
		// Colors
		/// .gray.opacity(0.2)
		static let textFieldTintColor = Color.gray.opacity(0.2)
		/// .white
		static let activeBackground = Color.white
		/// .black
		static let inactiveBackground = Color.black
		/// .gray.opacity(0.2)
		static let activeStrokeColor = Color.gray.opacity(0.2)
		/// .black
		static let inactiveStrokeColor = Color.black
		/// .white
		static let placeholderColor = Color.white
		/// .black
		static let checkmarkActiveColor = Color.black
		/// .white
		static let checkmarkInactiveColor = Color.white
		
		// Checkmark
		/// 2
		static let checkmarkLineWidth: CGFloat = 2
		/// CGSize(width: 15, height: 15)
		static let checkmarkSize = CGSize(width: 15, height: 15)
		
		// Text
		/// "Add item"
		static let placeholder = "Add item"
	}
}

extension InputArea {
	
	/// Defines the visual style of the input button area depending on interaction state.
	///
	/// Use `InputButtonStyle` to standardize the look and feel of the input area
	/// across different stages of interaction (e.g., when starting, editing, or completing input).
	///
	///  - Parameters:
	///   - `start`: Fixed width (300), black background, white tint.
	///   - `active`: Full width, white background, gray stroke, black tint.
	///   - `completed`: Compact width (72), black background, white tint.
	///   - `edit`: Same as `completed`, for editable but inactive state.
	///
	/// - Example:
	/// ```swift
	/// let style = InputButtonStyle.active
	/// style.backgroundColor  // .white
	/// style.maxWidth         // .infinity
	/// ```
	enum InputButtonStyle {
		case start
		case active
		case completed
		case edit
		
		/// Maximum width of the input area container.
		var maxWidth: CGFloat {
			switch self {
				case .start: 250
				case .active: .infinity
				case .completed, .edit: 72
			}
		}
		
		/// Background color of the input container.
		var backgroundColor: Color {
			switch self {
				case .active: .white
				default: .black
			}
		}
		
		/// Stroke color of the input container border.
		var strokeColor: Color {
			switch self {
				case .active: .gray.opacity(0.2)
				default: .black
			}
		}
		
		/// Tint color applied to icons or text caret.
		var tintColor: Color {
			switch self {
				case .active: .black
				default: .white
			}
		}
	}
}


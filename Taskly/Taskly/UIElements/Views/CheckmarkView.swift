//
//  CheckmarkView.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 29.04.25.
//

import SwiftUI

public struct CheckmarkView: View {
	private let color: Color
	private let lineWidth: CGFloat
	private let size: CGSize

	@State private var progress: CGFloat = 0

	public init(
		color: Color = .white,
		lineWidth: CGFloat = Theme.defaultLineWidth,
		size: CGSize = Theme.defaultSize
	) {
		self.color = color
		self.lineWidth = lineWidth
		self.size = size
	}

	public var body: some View {
		CheckmarkShape()
			.trim(from: 0, to: progress)
			.stroke(
				color,
				style: StrokeStyle(
					lineWidth: lineWidth,
					lineCap: .round,
					lineJoin: .bevel
				)
			)
			.frame(width: size.width, height: size.height)
			.onAppear {
				withAnimation(.easeOut(duration: 0.3)) {
					progress = 1
				}
			}
	}
}

// MARK: - Shape
private extension CheckmarkView {
	struct CheckmarkShape: Shape {
		func path(in rect: CGRect) -> Path {
			var path = Path()
			let start = CGPoint(x: rect.width * 0.2, y: rect.height * 0.5)
			let mid = CGPoint(x: rect.width * 0.45, y: rect.height * 0.75)
			let end = CGPoint(x: rect.width * 0.9, y: rect.height * 0.25)

			path.move(to: start)
			path.addLine(to: mid)
			path.addLine(to: end)

			return path
		}
	}
}

// MARK: - Theme
public extension CheckmarkView {
	enum Theme {
		// Layout
		/// CGSize(width: 20, height: 20)
		public static let defaultSize: CGSize = CGSize(width: 20, height: 20)
		/// 2
		public static let defaultLineWidth: CGFloat = 2
	}
}

// MARK: - Preview
#Preview {
	CheckmarkView(
		color: .black,
		lineWidth: 5,
		size: CGSize(width: 50, height: 50)
	)
}

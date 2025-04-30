//
//  AnimatedDividerView.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 29.04.25.
//

import SwiftUI

public struct AnimatedDividerView: View {
	@State private var progress: CGFloat = 0
	
	private let color: Color
	private let lineWidth: CGFloat
	private let animation: Animation
	
	public init(
		color: Color = .gray.opacity(0.2),
		lineWidth: CGFloat = 1,
		animation: Animation = .easeOut(duration: 0.6).delay(0.4)
	) {
		self.color = color
		self.lineWidth = lineWidth
		self.animation = animation
	}
	
	public var body: some View {
		DividerShape()
			.trim(from: 0, to: progress)
			.stroke(color, lineWidth: lineWidth)
			.opacity(progress == 0 ? 0 : 1)
			.frame(height: lineWidth)
			.onAppear {
				withAnimation(animation) {
					progress = 1
				}
			}
	}
}

// MARK: - Shape
private extension AnimatedDividerView {
	private struct DividerShape: Shape {
		func path(in rect: CGRect) -> Path {
			var path = Path()
			path.move(to: .init(x: 0, y: rect.midY))
			path.addLine(to: .init(x: rect.width, y: rect.midY))
			return path
		}
	}
}

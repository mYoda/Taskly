//
//  PlusToCheckmark.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 29.04.25.
//
import SwiftUI

public struct PlusToCheckmarkView: View {
	private var isCheckmarkShown: Bool
	private let color: Color
	private let lineWidth: CGFloat
	private let size: CGSize

	public init(
		isCheckmarkShown: Bool = false,
		color: Color = .gray,
		lineWidth: CGFloat = 5,
		size: CGSize = CGSize(width: 50, height: 50)
	) {
		self.isCheckmarkShown = isCheckmarkShown
		self.color = color
		self.lineWidth = lineWidth
		self.size = size
	}

	public var body: some View {
		ZStack {
			let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .bevel)

			// First line (horizontal → bottom part of checkmark)
			LineSegment(
				startPoint: isCheckmarkShown ? CGPoint(x: 0.2, y: 0.5) : CGPoint(x: 0.0, y: 0.5),
				endPoint: isCheckmarkShown ? CGPoint(x: 0.45, y: 0.75) : CGPoint(x: 1.0, y: 0.5)
			)
			.stroke(style: style)

			// Second line (vertical → top part of checkmark)
			LineSegment(
				startPoint: isCheckmarkShown ? CGPoint(x: 0.45, y: 0.75) : CGPoint(x: 0.5, y: 1.0),
				endPoint: isCheckmarkShown ? CGPoint(x: 0.9, y: 0.25) : CGPoint(x: 0.5, y: 0.0)
			)
			.stroke(style: style)
		}
		.foregroundStyle(color)
		.frame(size: size)
		.animation(.easeInOut(duration: 0.6), value: isCheckmarkShown)
	}
}

// MARK: - LineSegment
struct LineSegment: Shape {
	var startPoint: CGPoint
	var endPoint: CGPoint

	var animatableData: AnimatableSegment {
		get { AnimatableSegment(startPoint: startPoint, endPoint: endPoint) }
		set {
			startPoint = newValue.startPoint
			endPoint = newValue.endPoint
		}
	}

	func path(in rect: CGRect) -> Path {
		var path = Path()
		let start = CGPoint(x: startPoint.x * rect.width, y: startPoint.y * rect.height)
		let end = CGPoint(x: endPoint.x * rect.width, y: endPoint.y * rect.height)
		path.move(to: start)
		path.addLine(to: end)
		return path
	}
}

// MARK: - AnimatableSegment
struct AnimatableSegment: VectorArithmetic {
	var startPoint: CGPoint
	var endPoint: CGPoint

	static var zero: AnimatableSegment {
		AnimatableSegment(startPoint: .zero, endPoint: .zero)
	}

	static func + (lhs: AnimatableSegment, rhs: AnimatableSegment) -> AnimatableSegment {
		AnimatableSegment(
			startPoint: CGPoint(x: lhs.startPoint.x + rhs.startPoint.x,
								y: lhs.startPoint.y + rhs.startPoint.y),
			endPoint: CGPoint(x: lhs.endPoint.x + rhs.endPoint.x,
							  y: lhs.endPoint.y + rhs.endPoint.y)
		)
	}

	static func - (lhs: AnimatableSegment, rhs: AnimatableSegment) -> AnimatableSegment {
		AnimatableSegment(
			startPoint: CGPoint(x: lhs.startPoint.x - rhs.startPoint.x,
								y: lhs.startPoint.y - rhs.startPoint.y),
			endPoint: CGPoint(x: lhs.endPoint.x - rhs.endPoint.x,
							  y: lhs.endPoint.y - rhs.endPoint.y)
		)
	}

	mutating func scale(by rhs: Double) {
		startPoint.x *= rhs
		startPoint.y *= rhs
		endPoint.x *= rhs
		endPoint.y *= rhs
	}

	var magnitudeSquared: Double {
		Double(
			startPoint.x * startPoint.x +
			startPoint.y * startPoint.y +
			endPoint.x * endPoint.x +
			endPoint.y * endPoint.y
		)
	}

	static func == (lhs: AnimatableSegment, rhs: AnimatableSegment) -> Bool {
		lhs.startPoint == rhs.startPoint && lhs.endPoint == rhs.endPoint
	}
}


// MARK: - Preview
struct PlusToCheckmarkView_Previews: PreviewProvider {
	@State static var isCheckmarkShown = false

	static var previews: some View {
		VStack(spacing: 20) {
			PlusToCheckmarkView(isCheckmarkShown: isCheckmarkShown)
				.background(Color.black)
				.frame(width: 100, height: 100)

			Button("Toggle Checkmark") {
				withAnimation {
					isCheckmarkShown.toggle()
				}
			}
		}
		.padding()
		.previewLayout(.sizeThatFits)
	}
}

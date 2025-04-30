//
//  View+Common.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 29.04.25.
//

import Foundation
import SwiftUI

extension View {
	func frame(size: CGSize, alignment: Alignment = .center) -> some View {
		return self.frame(width: size.width, height: size.height, alignment: alignment)
	}
}

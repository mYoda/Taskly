//
//  TaskItem.swift
//  Taskly
//
//  Created by Anton Nechaiuk on 26.04.2025.
//

import Foundation
import Dependencies

typealias TaskID = UUID

struct TaskItem: Equatable, Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    
    init(
        id: UUID,
        title: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title ?? ""
        self.isCompleted = isCompleted
    }
} 

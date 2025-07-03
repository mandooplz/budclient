//
//  EventHandler.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: EventHandler
package struct Handler<Event>: Sendable where Event: Sendable {
    package let routine: @Sendable (Event) -> Void
    
    package func callAsFunction(_ event: Event) {
        self.routine(event)
    }
    
    package init(_ routine: @Sendable @escaping (Event) -> Void) {
        self.routine = routine
    }
}




// MARK: ProjectHubEvent
package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceID)
    case removed(ProjectSourceID)
    
    package typealias ProjectSourceID = String
}

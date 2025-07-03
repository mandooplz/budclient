//
//  EventHandler.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: EventHandler
package struct Handler<Event>: Sendable where Event: Sendable {
    package let routine: @Sendable (Event) -> Void
    
    package init(routine: @Sendable @escaping (Sendable) -> Void) {
        self.routine = routine
    }
}

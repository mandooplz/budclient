//
//  Handler.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


package struct Handler<Event>: Sendable where Event: Sendable {
    package let routine: @Sendable (Event) -> Void
    
    package func execute(_ event: Event) {
        self.routine(event)
    }
    
    package init(_ routine: @Sendable @escaping (Event) -> Void) {
        self.routine = routine
    }
}
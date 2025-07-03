//
//  Subscribable.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: Subscribable
@Server
package protocol Subscribable: AnyObject, Sendable {
    associatedtype Event: Sendable
    
    var eventHandlers: [SystemID: Handler<Event>] { get set }
    func hasHandler(system: SystemID) -> Bool
    func setHandler(ticket: Ticket, handler: Handler<Event>)
}

@Server
package extension Subscribable {
    func hasHandler(system: SystemID) -> Bool {
        self.eventHandlers[system] != nil
    }
    func setHandler(ticket: Ticket, handler: Handler<Event>) {
        self.eventHandlers[ticket.system] = handler
    }
}

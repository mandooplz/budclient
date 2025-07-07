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
    
    var eventHandlers: [ObjectID: Handler<Event>] { get set }
    func hasHandler(object: ObjectID) -> Bool
    func setHandler(ticket: SubscrieProjectSource, handler: Handler<Event>)
}

@Server
package extension Subscribable {
    func hasHandler(object: ObjectID) -> Bool {
        self.eventHandlers[object] != nil
    }
    func setHandler(ticket: SubscrieProjectSource, handler: Handler<Event>) {
        self.eventHandlers[ticket.object] = handler
    }
}

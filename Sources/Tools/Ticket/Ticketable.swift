//
//  Ticketable.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Collections


@MainActor
package protocol Ticketable: AnyObject {
    associatedtype ObjectTicket
    var tickets: Deque<ObjectTicket> { get set }
}


@MainActor
package extension Ticketable {
    func insert(_ ticket: ObjectTicket) {
        self.tickets.append(ticket)
    }
}


//
//  UpdaterInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Collections


// MARK: UpdaterInterface
@MainActor
package protocol UpdaterInterface: AnyObject, Sendable, Debuggable, Hookable {
    associatedtype Event: Sendable
    
    var queue: Deque<Event> { get set }
}

package extension UpdaterInterface {
    func appendEvent(_ event: Event) {
        queue.append(event)
    }
}

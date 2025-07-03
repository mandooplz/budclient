//
//  EventHandler.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: EventHandler
public typealias Callback = @Sendable () async -> Void



// MARK: EventDebuggable
@MainActor
package protocol EventDebuggable: AnyObject {
    var callback: Callback? { get set }
}

package extension EventDebuggable {
    func setCallbacK(_ handler: @escaping Callback) {
        self.callback = handler
    }
}

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
    func setCallback(_ handler: @escaping Callback) {
        self.callback = nil
        self.callback = handler
    }
}

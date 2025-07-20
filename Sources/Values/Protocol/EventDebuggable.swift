//
//  EventDebuggable.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation


// MARK: Callback
public typealias Callback = @Sendable @MainActor () -> Void


// MARK: EventDebuggable
@MainActor
public protocol EventDebuggable: AnyObject {
    var callback: Callback? { get set }
}

internal extension EventDebuggable {
    func setCallbackNil() {
        self.callback = nil
    }
}

public extension EventDebuggable {
    func setCallback(_ handler: @escaping Callback) {
        self.callback = { [weak self] in
            handler()
            self?.setCallbackNil()
        }
    }
}

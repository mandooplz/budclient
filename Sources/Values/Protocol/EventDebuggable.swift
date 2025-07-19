//
//  EventDebuggable.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation


// MARK: EventDebuggable
@MainActor
public protocol EventDebuggable: AnyObject {
    var callback: Callback? { get set }
}

public extension EventDebuggable {
    func setCallback(_ handler: @escaping Callback) {
        self.callback = nil
        self.callback = handler
    }
    
    func setCallbackNil() {
        self.callback = nil
    }
}

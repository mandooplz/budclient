//
//  Hookable.swift
//  BudClient
//
//  Created by 김민우 on 7/20/25.
//



// MARK: Hook
package typealias Hook = (@Sendable () async -> Void)


// MARK: Hookable
@MainActor
package protocol Hookable: AnyObject, Sendable {
    var captureHook: Hook? { get set }
    var computeHook: Hook? { get set }
    var mutateHook: Hook? { get set }
}

internal extension Hookable {
    func setCaptureHookNil() {
        self.captureHook = nil
    }
    
    func setMutateHookNil() {
        self.mutateHook = nil
    }
    
    func setComputeHookNil() {
        self.computeHook = nil
    }
}


package extension Hookable {
    func setCaptureHook(_ hook: @escaping Hook) {
        self.captureHook = {
            await hook()
            await self.setCaptureHookNil()
        }
    }
    
    func setMutateHook(_ hook: @escaping Hook) {
        self.mutateHook = {
            await hook()
            await self.setMutateHookNil()
        }
    }
    
    func setComputeHook(_ hook: @escaping Hook) {
        self.computeHook = {
            await hook()
            await self.setComputeHookNil()
        }
    }
}


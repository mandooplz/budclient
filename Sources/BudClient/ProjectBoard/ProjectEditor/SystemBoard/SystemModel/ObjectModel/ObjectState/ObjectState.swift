//
//  ObjectState.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "ObjectState")


// MARK: Object
@MainActor @Observable
public final class ObjectState: Sendable {
    // MARK: core
    init(target: StateID) {
        self.target = target
        
        ObjectStateManager.register(self)
    }
    func delete() {
        ObjectStateManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID
    
    public var permission: StatePermission = .readWrite
    
    
    // 상태를 표현하는 값의 종류(ValueType)
    var valueName: String = ""
    var valueType: ValueTypeID? = nil
    var valueSource: Any? = nil
    
    
    // MARK: action
    public func pushName() async {
        logger.start()
        
        await self.pushName(captureHook: nil)
    }
    func pushName(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            return
        }
    }
    
    public func createGetter() async {
        logger.start()
        
        await self.createGetter(captureHook: nil)
    }
    func createGetter(captureHook: Hook?) async {
        
    }
    
    public func createSetter() async {
        logger.start()
        
        await self.createSetter(captureHook: nil)
    }
    func createSetter(captureHook: Hook?) async {
        // capture
    }
    
    public func remove() async {
        
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ObjectStateManager.container[self] != nil
        }
        public var ref: ObjectState? {
            ObjectStateManager.container[self]
        }
    }
}


// MARK: Objec Manager
@MainActor @Observable
fileprivate final class ObjectStateManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectState.ID: ObjectState] = [:]
    fileprivate static func register(_ object: ObjectState) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectState.ID) {
        container[id] = nil
    }
}

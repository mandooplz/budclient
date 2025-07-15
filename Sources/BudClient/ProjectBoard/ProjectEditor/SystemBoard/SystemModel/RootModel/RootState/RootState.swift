//
//  RootState.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "RootState")


// MARK: Object
@MainActor @Observable
public final class RootState: Sendable {
    // MARK: core
    init(name: String,
         config: Config<RootModel.ID>,
         target: StateID) {
        self.name = name
        self.nameInput = name
        
        self.config = config
        self.target = target
        
        RootStateManager.register(self)
    }
    func delete() {
        RootStateManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<RootModel.ID>
    nonisolated let target: StateID
    
    var name: String
    var nameInput: String
    
    // State의 Value를 어떻게 편집하며 이들을 어떻게 관리할 것인가. 
    
    
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
    
    public func createGetter() async { }
    public func createSetter() async { }
    
    public func subscribeValueTypes() async {
        //
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            false
        }
        public var ref: RootState? {
            nil
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootStateManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootState.ID: RootState] = [:]
    fileprivate static func register(_ object: RootState) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootState.ID) {
        container[id] = nil
    }
}

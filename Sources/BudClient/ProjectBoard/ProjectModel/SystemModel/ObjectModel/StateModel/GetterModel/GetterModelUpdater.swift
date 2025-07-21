//
//  GetterModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("GetterModelUpdater")


// MARK: Object
extension GetterModel {
    @MainActor @Observable
    final class Updater: Debuggable, Hookable, UpdaterInterface {
        // MARK: core
        init(owner: GetterModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let owner: GetterModel.ID
        
        var queue: Deque<GetterSourceEvent> = []
        
        var issue: (any IssueRepresentable)?
        var captureHook: Hook?
        var computeHook: Hook?
        var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            await captureHook?()
            guard let getterModelRef = owner.ref else {
                setIssue(Error.getterModelIsDeleted)
                logger.failure("GetterModel이 존재하지 않아 실행 취소됩니다.")
                return
            }
            
            fatalError()
        }
        
        
        // MARK: value
        public enum Error: String, Swift.Error {
            case getterModelIsDeleted
        }
    }
}

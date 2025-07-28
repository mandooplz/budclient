//
//  ValueModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/29/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = BudLogger("ValueModelUpdater")


// MARK: Object
extension ValueModel {
    @MainActor @Observable
    final class Updater: UpdaterInterface, Hookable {
        // MARK: core
        init(owner: ValueModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ValueModel.ID
        
        var queue: Deque<ValueSourceEvent> = []
        var issue: (any IssueRepresentable)?
        
        package var captureHook: Hook?
        package var computeHook: Hook?
        package var mutateHook: Hook?
        
        
        // MARK: action
        func update() async {
            logger.start()
            
            // capture
            await captureHook?()
            guard let valueModelRef = self.owner.ref else {
                setIssue(Error.valueModelIsDeleted)
                logger.failure("ValueModel이 존재하지 않아 실행 취소됩니다.")
                return
            }
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case valueModelIsDeleted
        }
    }
}

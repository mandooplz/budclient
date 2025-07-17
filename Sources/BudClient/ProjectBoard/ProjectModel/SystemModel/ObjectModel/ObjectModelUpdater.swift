//
//  ObjectModelUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "ObjectModel.Updater")


// MARK: Object
extension ObjectModel {
    @MainActor @Observable
    final class Updater: Sendable {
        // MARK: core
        init(owner: ObjectModel.ID) {
            self.owner = owner
        }
        
        
        // MARK: state
        nonisolated let id = UUID()
        nonisolated let owner: ObjectModel.ID
        
        
        // MARK: action
        func update(mutateHook: Hook? = nil) async {
        case .modified(let diff):
            // modify ObjectModel
            guard let objectModel = systemModelRef.getObjectModel(diff.target) else {
                setIssue(Error.alreadyRemoved)
                logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 삭제된 상태입니다.")
                return
            }
            
            objectModel.ref?.name = diff.name
            
        case .removed(let diff):
            // remove ObjectModel
            guard systemModelRef.isObjectExist(diff.target) == true else {
                setIssue(Error.alreadyRemoved)
                logger.failure("\(diff.target)에 대응되는 ObjectModel이 이미 삭제된 상태입니다.")
                return
            }
            
            for (idx, objectModel) in systemModelRef.objectModels.enumerated() {
                if let objectModelRef = objectModel.ref,
                   objectModelRef.target == diff.target {
                    systemModelRef.objectModels.remove(at: idx)
                    objectModelRef.delete()
                    break
                }
            }
        }
        
        
        // MARK: value
    }
}


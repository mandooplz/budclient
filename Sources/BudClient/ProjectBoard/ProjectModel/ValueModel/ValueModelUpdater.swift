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
            guard queue.count > 0 else {
                setIssue(Error.eventQueueIsEmpty)
                logger.failure("이벤트 큐가 비어있습니다.")
                return
            }
            
            // mutate
            await mutateHook?()
            while queue.isEmpty == false {
                let projectModelRef = valueModelRef.config.parent.ref!
                let event = queue.removeFirst()
                
                switch event {
                case .modified(let diff):
                    // modified ValueModel
                    valueModelRef.updatedAt = diff.updatedAt
                    valueModelRef.order = diff.order
                    
                    valueModelRef.name = diff.name
                    valueModelRef.nameInput = diff.name
                    
                    valueModelRef.description = diff.description
                    valueModelRef.descriptionInput = diff.description
                    
                    valueModelRef.fields = diff.fields
                    valueModelRef.fieldsInput = diff.fields
                    
                    logger.end("modified ValueModel")
                case .removed:
                    // cleanUp State, Getter, Setter
                    updateTypeOfValues(valueModelRef)
                    
                    // remove ValueModel
                    projectModelRef.values[valueModelRef.target] = nil
                    valueModelRef.delete()
                    
                    logger.end("removed ValueModel")
                }
            }
        }
        
        
        // MARK: helphers
        private func updateTypeOfValues(_ valueModelRef: ValueModel) {
            let valueType = valueModelRef.target
            let projectModelRef = valueModelRef.config.parent.ref!
            
            // update StateModel.stateValue
            let stateModels = projectModelRef.systems.values
                .compactMap { systemModel in systemModel.ref }
                .flatMap { $0.objects.values }
                .compactMap { objectModel in objectModel.ref }
                .flatMap { $0.states.values }
            
            stateModels
                .compactMap { $0.ref }
                .filter { $0.stateValue?.type == valueType }
                .forEach {
                    let newValue = $0.stateValue?.setType(nil)
                    $0.stateValue = newValue
                    $0.stateValueInput = newValue
                }
            
            // update GetterModel.parameters & parameterInput
            let getterModels = stateModels
                .compactMap { $0.ref }
                .flatMap { $0.getters.values }
            
            getterModels
                .compactMap { $0.ref }
                .forEach { getterModelRef in
                    getterModelRef.parameters
                        .enumerated()
                        .filter { $0.element.type == valueType }
                        .forEach { (index, parameterValue) in
                            let newValue = parameterValue.setType(nil)
                            
                            getterModelRef.parameters[index] = newValue
                            getterModelRef.parameterInput[index] = newValue
                        }
                }
            
            // update GetterModel.result & resultInput
            getterModels
                .compactMap { $0.ref }
                .forEach { getterModelRef in
                    getterModelRef.result = nil
                    getterModelRef.resultInput = nil
                }
            
            
            // update SetterModel.parameters & parameterInput
            let setterModels = stateModels
                .compactMap { $0.ref }
                .flatMap { $0.setters.values }
            
            setterModels
                .compactMap { $0.ref }
                .forEach { setterModelRef in
                    setterModelRef.parameters
                        .enumerated()
                        .filter { $0.element.type == valueType }
                        .forEach { (index, parameterValue) in
                            let newValue = parameterValue.setType(nil)
                            
                            setterModelRef.parameters[index] = newValue
                            setterModelRef.parameterInput[index] = newValue
                        }
                }
            
            
        }
        
        
        // MARK: value
        enum Error: String, Swift.Error {
            case valueModelIsDeleted
            case eventQueueIsEmpty
        }
    }
}

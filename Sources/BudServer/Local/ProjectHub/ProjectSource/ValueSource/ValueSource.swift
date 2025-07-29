//
//  ValueSource.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import BudMacro
import FirebaseFirestore
import Values

private let logger = BudLogger("ValueSource")


// MARK: Object
@MainActor
package final class ValueSource: ValueSourceInterface {
    // MARK: core
    init(id: ID, target: ValueID, owner: ProjectSource.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        ValueSourceManager.register(self)
    }
    func delete() {
        ValueSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: ValueID
    nonisolated let owner: ProjectSource.ID
    
    package func setName(_ value: String) async {
        logger.start()
        
        fatalError()
    }
    package func setFields(_ value: [ValueField]) async {
        logger.start()
        
        fatalError()
    }
    package func setDescription(_ value: String) async {
        logger.start()
        
        fatalError()
    }
    
    var handler: EventHandler?
    package func appendHandler(requester: ObjectID,
                               _ handler: EventHandler) async {
        logger.start()
        
        // ProjectSource.appendHandler()에서 처리됨
        // mutate
        self.handler = handler
        return
    }
    
    
    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        // Firebase에서 알아서 처리됨
        return
    }
    
    package func removeValue() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ValueSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let valueSource = self.id
        let projectSource = self.owner
        
        let valueSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.ValueSources).document(valueSource.value)
        
        // compute
        do {
            try await valueSourceDocRef.delete()
        } catch {
            logger.failure("Firebase에서 ValueSource 삭제 실패\n\(error) ")
            return
        }
    }
    
    
    // MARK: value
    package typealias EventHandler = Handler<ValueSourceEvent>
    
    @MainActor
    package struct ID: ValueSourceIdentity {
        package let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            ValueSourceManager.container[self] != nil
        }
        package var ref: ValueSource? {
            ValueSourceManager.container[self]
        }
    }
    
    @ShowState
    package struct Data: Codable {
        @DocumentID var id: String?
        var target: ValueID
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        var name: String
        var description: String?
        var fields: [ValueField]
        
        // MARK: core
        init(name: String = "New Value",
             fields: [ValueField] = []) {
            self.target = ValueID()
            self.order = 0
            self.name = name
            self.fields = fields
        }
        
        
        // MARK: operator
        func getDiff(id: ValueSource.ID) -> ValueSourceDiff {
            let now = Date.now
            
            return .init(id: id,
                         target: self.target,
                         createdAt: self.createdAt?.dateValue() ?? now,
                         updatedAt: self.updatedAt?.dateValue() ?? now,
                         order: self.order,
                         name: self.name,
                         description: self.description,
                         fields: self.fields)
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class ValueSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [ValueSource.ID: ValueSource] = [:]
    fileprivate static func register(_ object: ValueSource) {
        self.container[object.id] = object
    }
    fileprivate static func unregister(_ id: ValueSource.ID) {
        self.container[id] = nil
    }
}



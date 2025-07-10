//
//  SystemSource.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import FirebaseFirestore
import Values


// MARK: Object
@MainActor
package final class SystemSource: Sendable {
    // MARK: core
    init(id: SystemSourceID,
         target: SystemID,
         parent: ProjectSourceID) {
        self.id = id
        self.target = target
        self.parent = parent
        
        SystemSourceManager.register(self)
    }
    func delete() {
        SystemSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: SystemSourceID
    nonisolated let target: SystemID
    nonisolated let parent: ProjectSourceID
    
    package func setName(_ value: String) {
        // compute
        guard let projectSourceRef = ProjectSourceManager.get(parent) else {
            return
        }
        
        let db = Firestore.firestore()
        let nameUpdater = State.getNameUpdater(value)
        let docRef = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
        
        docRef.updateData(nameUpdater)   
    }
    
    
    // MARK: action
    
    
    
    // MARK: value
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var target: SystemID
        var name: String
        var location: Location
        var rootModel: Root? // 여기서 Root에 대해 설명할 필요가 있을까.
        
        package struct Root: Hashable, Codable {
            let target: ObjectID
            let name: String
            let states: [StateID]
            let actions: [ActionID]
        }
    }
    package enum State: Sendable, Hashable {
        static let name = "name"
        static let location = "location"
        
        static func getNameUpdater(_ value: String) -> [String:Any] {
            [name: value]
        }
    }
}


// MARK: Object Manager
@MainActor
package final class SystemSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemSourceID: SystemSource] = [:]
    fileprivate static func register(_ object: SystemSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemSourceID) {
        container[id] = nil
    }
    package static func get(_ id: SystemSourceID) -> SystemSource? {
        container[id]
    }
}

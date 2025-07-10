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
    
    private var listeners: [ObjectID: Listener] = [:]
    package func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) {
        let db = Firestore.firestore()
        
        // rootSource listener
        let rootSourceListener = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.RootSources.name)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let _ = RootSourceID(documentId)
                    
                    switch changed.type {
                    case .added:
                        fatalError()
                    case .modified:
                        fatalError()
                    case .removed:
                        fatalError()
                    }
                }
            }
        
        // objectSource listener
        let objectSource = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.ObjectSources.name)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let _ = RootSourceID(documentId)
                }
            }
    }
    package func removeHandler(requester: ObjectID) {
        listeners[requester]?.rootSource.remove()
        listeners[requester]?.objectSource.remove()
        listeners[requester] = nil
    }
    // MARK: action
    
    
    
    // MARK: value
    private struct Listener {
        let rootSource: ListenerRegistration
        let objectSource: ListenerRegistration
    }
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var target: SystemID
        var name: String
        var location: Location
        var rootModel: Root?
        
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

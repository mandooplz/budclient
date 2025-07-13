//
//  SystemSource.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import FirebaseFirestore

private let logger = WorkFlow.getLogger(for: "SystemSource")


// MARK: Object
@MainActor
package final class SystemSource: SystemSourceInterface {
    // MARK: core
    init(id: ID,
         target: SystemID,
         parent: ProjectSource.ID) {
        self.id = id
        self.target = target
        self.parent = parent
        
        SystemSourceManager.register(self)
    }
    func delete() {
        SystemSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: SystemID
    nonisolated let parent: ProjectSource.ID
    
    package func setName(_ value: String) {
        logger.start()
        
        // compute
        let db = Firestore.firestore()
        let docRef = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
        
        let updateData: [String: Any] = [
            "name": value
        ]
        
        docRef.updateData(updateData)
    }
    
    private var listeners: [ObjectID: Listener] = [:]
    package func hasHandler(requester: ObjectID) -> Bool {
        listeners[requester] != nil
    }
    package func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) {
        logger.start()
        
        let db = Firestore.firestore()
        
        // rootSource listener
        let rootSourceListener = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.RootSources.name)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    let report = logger.getLog("\(error!)")
                    logger.raw.fault("\(report)")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let _ = RootSource.ID(documentId)
                    
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
        let objectSourceListener = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.ObjectSources.name)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    let report = logger.getLog("\(error!)")
                    logger.raw.fault("\(report)")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let _ = RootSource.ID(documentId)
                }
            }
        
        let listener = Listener(rootSource: rootSourceListener,
                                objectSource: objectSourceListener)
        self.listeners[requester] = listener
    }
    package func removeHandler(requester: ObjectID) {
        listeners[requester]?.rootSource.remove()
        listeners[requester]?.objectSource.remove()
        listeners[requester] = nil
    }
    
    package func notifyNameChanged() async {
        return
    }
    
    
    // MARK: action
    package func addSystemTop() async {
        logger.start()
        
        fatalError()
    }
    package func addSystemLeft() async {
        logger.start()
        
        fatalError()
    }
    package func addSystemRight() async {
        logger.start()
        
        fatalError()
    }
    package func addSystemBottom() async {
        logger.start()
        
        fatalError()
    }
    
    package func remove() async {
        logger.start()
        
        fatalError()
    }
    
    
    
    // MARK: value
    @MainActor
    package struct ID: SystemSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            SystemSourceManager.container[self] != nil
        }
        package var ref: SystemSource? {
            SystemSourceManager.container[self]
        }
    }
    private struct Listener {
        let rootSource: ListenerRegistration
        let objectSource: ListenerRegistration
    }
    struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var target: SystemID
        var name: String
        var location: Location
        var rootModel: Root?
        
        struct Root: Hashable, Codable {
            let target: ObjectID
            let name: String
            let states: [StateID]
            let actions: [ActionID]
        }
    }
}


// MARK: Object Manager
@MainActor
package final class SystemSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemSource.ID: SystemSource] = [:]
    fileprivate static func register(_ object: SystemSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemSource.ID) {
        container[id] = nil
    }
}

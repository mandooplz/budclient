//
//  ProjectSource.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation
import Values
import Collections
import FirebaseFirestore
import os


// MARK: Object
@MainActor
package final class ProjectSource: Sendable {
    // MARK: core
    init(id: ProjectSourceID,
         target: ProjectID) {
        self.id = id
        self.target = target
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id: ProjectSourceID
    nonisolated let target: ProjectID
    
    private var listeners: [ObjectID: ListenerRegistration] = [:]
    private typealias Manager = ProjectSourceManager
    
    package var editTicket: EditProjectSourceName?
    
    package func hasHandler(object: ObjectID) -> Bool {
        listeners[object] != nil
    }
    package func setHandler(ticket: SubscrieProjectSource,
                            handler: Handler<ProjectSourceEvent>) {
        guard listeners[ticket.object] == nil else { return }
        
        let db = Firestore.firestore()
        let documentRef = db.collection(ProjectSources.name)
            .document(id.value)
        
        listeners[ticket.object] = documentRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                Logger().error("Error fetching document: \(error!)")
                return
            }
            
            guard let newName = try? document.data(as: Data.self).name else {
                Logger().error("Invalid or missing 'name' field in document: \(document.documentID)")
                return
            }
            let event = ProjectSourceEvent.modified(newName)
            
            handler.execute(event)
        }
    }
    package func removeHandler(object: ObjectID) {
        self.listeners[object]?.remove()
        self.listeners[object] = nil
    }
    
    
    // MARK: action
    package func editProjectName() throws {
        guard Manager.isExist(id) else { return }
        guard let newName = editTicket?.name else { return }
        
        // FireStore의 Projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
        let db = Firestore.firestore()
        let documentRef = db.collection(ProjectSources.name).document(id.value)
        documentRef.updateData(State.getNameUpdater(newName))
        self.editTicket = nil
    }
    package func remove() {
        guard Manager.isExist(id) else { return }
        
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // FireStore에서 문서 삭제
        let db = Firestore.firestore()
        db.collection(ProjectSources.name).document(id.value).delete()
    }
    
    package func createFirstSystem() async throws  {
        // database
        let db = Firestore.firestore()
        
        // reference
        let projectSourceRef = db.collection(ProjectSources.name)
            .document(id.value)
        let systemSourcesRef = projectSourceRef.collection(ProjectSources.SystemSources.name)
        
        // transaction
        let _ = try await db.runTransaction { @Sendable transaction, errorPointer in
            do {
                // check ProjectSource.systemModelCount
                let data = try transaction.getDocument(projectSourceRef)
                    .data(as: ProjectSource.Data.self)
                guard data.systemModelCount == 0 else {
                    return nil
                }
                
                // create SystemSource
                let newSystemSourceRef = systemSourcesRef.document()
                let newData = SystemSource.Data(name: "First System",
                                                location: .origin)
                
                try transaction.setData(from: newData, forDocument: newSystemSourceRef)
                
                
                // increase ProjectSource.systemModelCount
                transaction.updateData([
                    ProjectSource.State.systemModelCount: FieldValue.increment(Int64(1))
                ], forDocument: projectSourceRef)
                
                return
            } catch(let error as NSError) {
                errorPointer?.pointee = error
                return nil
            }
        }
    }
    
    
    // MARK: value
    // Data는 아래 경우에 사용된다.
    // 1. 리스너 등록
    // 2. 리스너를 통해 이벤트 처리
    // 3. 상태 업데이트
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        package var name: String
        package var creator: UserID
        package var target: ProjectID
        package var systemModelCount: Int
    }
    package enum State: Sendable {
        static let name = "name"
        static let creator = "creator"
        static let target = "target"
        static let systemModelCount = "systemModelCount"
        
        static func getNameUpdater(_ value: String) -> [String: Any] {
            [name: value]
        }
        static func getSystemModelCountUpdater(_ value: Int) -> [String: Any] {
            [systemModelCount: value]
        }
    }
}


// MARK: Object Manager
@MainActor
package final class ProjectSourceManager: Sendable {
    fileprivate static var container: [ProjectSourceID : ProjectSource] = [:]
    fileprivate static func register(_ object: ProjectSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSourceID) {
        container[id] = nil
    }
    package static func get(_ id: ProjectSourceID) -> ProjectSource? {
        container[id]
    }
    package static func isExist(_ id: ProjectSourceID) -> Bool {
        container[id] != nil
    }
}


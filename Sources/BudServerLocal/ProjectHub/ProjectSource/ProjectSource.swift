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
    
    private let db = Firestore.firestore()
    private var listeners: [ObjectID: ListenerRegistration] = [:]
    private typealias Manager = ProjectSourceManager
    
    package var editTicket: EditProjectSourceName?
    
    package func hasHandler(object: ObjectID) -> Bool {
        listeners[object] != nil
    }
    package func setHandler(ticket: SubscrieProjectSource,
                            handler: Handler<ProjectSourceEvent>) {
        guard listeners[ticket.object] == nil else { return }
        
        listeners[ticket.object] = db.collection(DB.ProjectSources).document(id.value)
            .addSnapshotListener { documentSnapshot, error in
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
    package func processTicket() throws {
        guard Manager.isExist(id) else { return }
        guard let newName = editTicket?.name else { return }
        
        // FireStore의 Projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
        let document = db.collection(DB.ProjectSources).document(id.value)
        document.updateData(State.getNameUpdator(newName))
    }
    package func remove() {
        guard Manager.isExist(id) else { return }
        
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // FireStore에서 문서 삭제
        db.collection(DB.ProjectSources).document(id.value).delete()
    }
    
    
    // MARK: value
    // Data가 언제 사용되는가.
    // 1. 리스너 등록
    // 2. 리스너를 통해 이벤트 처리
    // 3. 상태 업데이트 ->
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        package var name: String
        package var creator: UserID
        package var target: ProjectID
    }
    package enum State: Sendable {
        static let name = "name"
        static let creator = "creator"
        static let target = "target"
        
        static func getNameUpdator(_ value: String) -> [String: Any] {
            [name: value]
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


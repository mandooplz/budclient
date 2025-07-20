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
import BudMacro

private let logger = BudLogger("ProjectSource")


// MARK: Object
@MainActor
package final class ProjectSource: ProjectSourceInterface {
    // MARK: core
    init(id: ID, name: String, target: ProjectID, parent: ProjectHub.ID) {
        self.id = id
        self.target = target
        self.parent = parent
        
        self.name = name
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        self.listener?.remove()
        
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    package nonisolated let id: ID
    nonisolated let target: ProjectID
    nonisolated let parent: ProjectHub.ID
    
    var systemSources: [SystemID: SystemSource.ID] = [:]
    
    var name: String
    package func setName(_ value: String) {
        logger.start(value)
        
        // set ProjectSource.name
        let db = Firestore.firestore()
        let docRef = db.collection(DB.projectSources).document(id.value)
        
        let updateData: [String: Any] = [
            ProjectSource.Data.name: value
        ]
        
        docRef.updateData(updateData) { error in
            if let error {
                // Firestore 에러인지 확인하고 에러 코드를 가져옵니다.
                let fireStoreError = error as NSError
                let errorCode = FirestoreErrorCode.Code(rawValue: fireStoreError.code)
                
                // 에러 코드가 notFound인지 확인합니다.
                if errorCode == .notFound {
                    logger.failure("문서가 존재하지 않아 업데이트에 실패했습니다. (삭제되었을 수 있습니다)")
                } else {
                    logger.failure("Firestore 업데이트 중 에러 발생 \n\(error)")
                }
            } else {
                print("문서가 성공적으로 업데이트되었습니다.")
            }
        }
    }
    
    package var listener: ListenerRegistration?
    package var handlers: [ObjectID:EventHandler] = [:]
    package func appendHandler(for requester: ObjectID, _ handler: EventHandler) {
        logger.start()
        
        
        
        // mutate
        self.handlers[requester] = handler
        
        // mutate - firebase
        let db = Firestore.firestore()
        let systemSourceCollectionRef = db.collection(DB.projectSources)
            .document(id.value)
            .collection(DB.systemSources)
        guard self.listener == nil else {
            logger.failure("Firebase 리스너가 이미 등록되어 있습니다.")
            return
        }
        self.listener = systemSourceCollectionRef
            .addSnapshotListener({ snapshot, error in
                guard let snapshot else {
                    logger.failure(error!)
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let systemSource = SystemSource.ID(documentId)
                    
                    let data: SystemSource.Data
                    do {
                        data = try changed.document.data(as: SystemSource.Data.self)
                    } catch {
                        logger.failure("SystemSource 디코딩 실패 \(documentId)\n\(error)")
                        return
                    }
                    
                    guard let diff = SystemSourceDiff(from: data) else {
                        logger.failure("SystemSourceDiff 변환 실패")
                        return
                    }
                    
                    
                    switch changed.type {
                    case .added:
                        // create SystemSource
                        let systemSourceRef = SystemSource(id: systemSource,
                                                           target: data.target,
                                                           parent: self.id)
                        
                        self.systemSources[data.target] = systemSourceRef.id

                        // serve event
                        handler.execute(.added(diff))
                    case .modified:
                        guard let systemSourceRef = systemSource.ref else {
                            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                            return
                        }
                        
                        systemSourceRef.handler?.execute(.modified(diff))
                    case .removed:
                        guard let systemSourceRef = systemSource.ref else {
                            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                            return
                        }
                        
                        systemSourceRef.handler?.execute(.removed)
                        
                        // delete SystemSource
                        self.systemSources[data.target] = nil
                        systemSource.ref?.delete()
                    }
                }
            })
    }
    package func removeHandler(of requester: ObjectID) async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // mutate
        self.handlers[requester] = nil
        
        self.listener?.remove()
        self.listener = nil
    }
    package func sendInitialEvents(to requester: ObjectID) async {
        logger.start()
        
        // Firebase.listerner를 등록하는 과정에서 자체적으로 이벤트를 전달한다.
    }
    
    package func notifyNameChanged() async {
        logger.start()
        
        // Firebase에서 내부적으로 이벤트를 전달한다.
        return
    }
    
    
    // MARK: action
    package func createSystem() async  {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // database
        let firebaseDB = Firestore.firestore()
        
        // get ref
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(id.value)
        
        let systemSourceCollectionRef = projectSourceDocRef
            .collection(DB.systemSources)
        
        // transaction
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get ProjectSource.Data
                    let projectSourceData = try transaction
                        .getDocument(projectSourceDocRef)
                        .data(as: Data.self)
                    
                    // check System alreadyExist
                    guard projectSourceData.systemLocations.isEmpty else {
                        logger.failure("(0,0) 위치에 첫 번째 System이 이미 존재합니다.")
                        return
                    }
                    
                    // create SystemSource
                    let newSystemSourceDocRef = systemSourceCollectionRef
                        .document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "First System",
                                                                location: .origin)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDocRef)
                    
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocationSet: Set<Location> = [newSystemSourceData.location]
                    
                    transaction.updateData([
                        Data.systemLocations : newSystemLocationSet.encode()
                    ], forDocument: projectSourceDocRef)
                    
                    return
                } catch(let error as NSError) {
                    logger.failure(error)
                    return nil
                }
            }
        } catch {
            logger.failure("트랜잭션 실패\n\(error)")
            return
        }
    }
    package func removeProject() {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectHubRef = parent.ref!
        
        // delete ProjectSource
        projectHubRef.projectSources[target] = nil
        self.delete()
        
        // cancel ProjectSourceDocument in FireStore
        let db = Firestore.firestore()
        db.collection(DB.projectSources)
            .document(id.value)
            .delete()
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: ProjectSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            ProjectSourceManager.container[self] != nil
        }
        package var ref: ProjectSource? {
            ProjectSourceManager.container[self]
        }
    }
    
    @ShowState
    struct Data: Hashable, Codable {
        @DocumentID var id: String?
        package var name: String
        package var creator: UserID
        package var target: ProjectID
        
        package var systemLocations: Set<Location>
        
        init(name: String, creator: UserID) {
            self.name = name
            self.creator = creator
            self.target = ProjectID()
            self.systemLocations = []
        }
    }
    package typealias EventHandler = Handler<ProjectSourceEvent>
}


// MARK: Object Manager
@MainActor
fileprivate final class ProjectSourceManager: Sendable {
    fileprivate static var container: [ProjectSource.ID : ProjectSource] = [:]
    fileprivate static func register(_ object: ProjectSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSource.ID) {
        container[id] = nil
    }
}


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
    init(id: ID,
         target: ProjectID,
         owner: ProjectHub.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        self.listener?.remove()
        
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    package nonisolated let id: ID
    nonisolated let target: ProjectID
    nonisolated let owner: ProjectHub.ID
    
    var systems: [SystemID: SystemSource.ID] = [:]
    var values: [ValueID: ValueSource.ID] = [:]
    
    package func setName(_ value: String) {
        logger.start(value)
        
        // set ProjectSource.name
        let db = Firestore.firestore()
        let docRef = db.collection(DB.ProjectSources).document(id.value)
        
        let updateData: [String: Any] = [
            Data.name: value
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
    
    var listener: EventListener?
    package var handlers: EventHandler?
    package func appendHandler(requester: ObjectID, _ handler: EventHandler) {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행취소됩니다.")
            return
        }
        guard self.listener == nil else {
            logger.failure("Firebase 리스너가 이미 등록되어 있습니다.")
            return
        }
        let me = self.id
        
        // compute
        let systemSourceCollectionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(id.value)
            .collection(DB.SystemSources)
        
        let valueSourceCollectionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(id.value)
            .collection(DB.ValueSources)
        
        let systemListener = systemSourceCollectionRef
            .addSnapshotListener({ snapshot, error in
                guard let snapshot else {
                    logger.failure(error!)
                    return
                }
                
                snapshot.documentChanges.forEach { [weak self] changed in
                    let documentId = changed.document.documentID
                    let systemSource = SystemSource.ID(documentId)
                    
                    let data: SystemSource.Data
                    let diff: SystemSourceDiff
                    do {
                        data = try changed.document.data(as: SystemSource.Data.self)
                        diff = data.getDiff(id: systemSource)
                    } catch {
                        logger.failure("SystemSource 디코딩 실패 \(documentId)\n\(error)")
                        return
                    }
                    
                    
                    switch changed.type {
                    case .added:
                        // create SystemSource
                        if me.ref?.systems[data.target] == nil {
                            let systemSourceRef = SystemSource(id: systemSource,
                                                               target: data.target,
                                                               parent: me)
                            
                            me.ref?.systems[data.target] = systemSourceRef.id
                        }
                        
                        // serve event
                        handler.execute(.systemAdded(diff))
                    case .modified:
                        // notify
                        systemSource.ref?.handler?.execute(.modified(diff))
                    case .removed:
                        // delete SystemSource
                        me.ref?.systems[data.target] = nil
                        systemSource.ref?.delete()
                        
                        // notify
                        systemSource.ref?.handler?.execute(.removed)
                    }
                }
            })
        
        let valueListener = valueSourceCollectionRef
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.failure(error!)
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let valueSource = ValueSource.ID(documentId)
                    
                    let data: ValueSource.Data
                    let diff: ValueSourceDiff
                    do {
                        data = try changed.document.data(as: ValueSource.Data.self)
                        diff = data.getDiff(id: valueSource)
                    } catch {
                        logger.failure("ValueSource 디코딩 실패 \(documentId)")
                        return
                    }
                    
                    
                    switch changed.type {
                    case .added:
                        if me.ref?.values[data.target] == nil {
                            let valueSourceRef = ValueSource(id: valueSource,
                                                             target: data.target,
                                                             owner: me)
                            
                            me.ref?.values[data.target] = valueSourceRef.id
                        }
                        
                        handler.execute(.valueAdded(diff))
                    case .modified:
                        valueSource.ref?.handler?.execute(.modified(diff))
                    case .removed:
                        // delete ValueSource
                        me.ref?.values[data.target] = nil
                        valueSource.ref?.delete()
                        
                        valueSource.ref?.handler?.execute(.removed)
                    }
                }
            }
        
        // mutate
        self.handlers = handler
        self.listener = .init(system: systemListener,
                              value: valueListener)
    }
    
    package func registerSync(_ object: ObjectID) async {
        logger.start()
        
        logger.failure("Firebase에서 자체적으로 처리됨")
    }
    
    // MARK: action
    package func synchronize() async {
        logger.start()
        
        // Firebase.listerner를 등록하는 과정에서 자체적으로 이벤트를 전달한다.
    }
    package func notifyStateChanged() async {
        logger.start()
        
        // Firebase에서 내부적으로 이벤트를 전달한다.
        return
    }
    
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
            .collection(DB.ProjectSources)
            .document(id.value)
        
        let systemSourceCollectionRef = projectSourceDocRef
            .collection(DB.SystemSources)
        
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
    package func createValue() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let valueSourceCollectionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(self.id.value)
            .collection(DB.ValueSources)
        
        // compute
        let newValueSourceData = ValueSource.Data()
        
        do {
            let _ = try valueSourceCollectionRef.addDocument(from: newValueSourceData)
        } catch {
            logger.failure("Firebase ValueSource 문서 생성 실패\n\(error)")
            return
        }
    }
    
    package func removeProject() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectHubRef = self.owner.ref!
        
        let projectSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(self.id.value)
        
        // cancel ProjectSourceDocument in FireStore
        do {
            try await projectSourceDocRef.delete()
        } catch {
            logger.failure("ProjectSource 삭제 실패\n\(error)")
            return
        }
        
        // mutate
        self.cleanUpProjectSource()
        
        projectHubRef.projectSources[self.target] = nil
        self.delete()
    }
    
    
    // MARK: Helhphers
    private func cleanUpProjectSource() {
        // delete Getters
        self.systems.values
            .compactMap { $0.ref }.flatMap { $0.objects.values }
            .compactMap { $0.ref }.flatMap { $0.states.values }
            .compactMap { $0.ref }.flatMap { $0.getters.values }
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        
        // delete Setters
        self.systems.values
            .compactMap { $0.ref }.flatMap { $0.objects.values }
            .compactMap { $0.ref }.flatMap { $0.states.values }
            .compactMap { $0.ref }.flatMap { $0.setters.values }
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        // delete States
        self.systems.values
            .compactMap { $0.ref }.flatMap { $0.objects.values }
            .compactMap { $0.ref }.flatMap { $0.states.values }
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        // delete Actions
        self.systems.values
            .compactMap { $0.ref }.flatMap { $0.objects.values }
            .compactMap { $0.ref }.flatMap { $0.actions.values }
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        // delete Objects
        self.systems.values
            .compactMap { $0.ref }.flatMap { $0.objects.values }
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        // delete Systems
        self.systems.values
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        // delete Values
        self.values.values
            .compactMap { $0.ref }
            .forEach { $0.delete() }
    }
    
    
    // MARK: value
    package typealias EventHandler = Handler<ProjectSourceEvent>
    
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
        package var target: ProjectID
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        package var name: String
        package var creator: UserID
        
        package var systemLocations: Set<Location>
        
        // MARK: core
        init(name: String,
             creator: UserID) {
            self.target = ProjectID()
            self.order = 0
            
            self.name = name
            self.creator = creator
            self.systemLocations = []
        }
        
        // MARK: operator
        func getDiff(id: ProjectSource.ID) -> ProjectSourceDiff {
            let now = Date.now
            
            return .init(id: id,
                         target: self.target,
                         name: self.name,
                         createdAt: self.createdAt?.dateValue() ?? now,
                         updatedAt: self.updatedAt?.dateValue() ?? now,
                         order: self.order)
        }
    }
    
    struct EventListener {
        let system: ListenerRegistration
        let value: ListenerRegistration
        
        func remove() -> Void {
            self.system.remove()
            self.value.remove()
        }
    }
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


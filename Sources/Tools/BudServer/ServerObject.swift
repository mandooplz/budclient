//
//  BudServerObject.swift
//  BudClient
//
//  Created by 김민우 on 7/2/25.
//
import Foundation


// MARK: BudServerObject
@BudServer
package protocol ServerObject: AnyObject, Sendable {
    associatedtype ID: ServerObjectID where ID.Object == Self
    nonisolated var id: ID { get }
}


// MARK: BudObjectID
@BudServer
package protocol ServerObjectID: Sendable, Hashable {
    associatedtype Object: ServerObject where Object.ID == Self
    associatedtype Manager: ServerObjectManager where Manager.Object == Object
    var value: UUID { get }
}

@BudServer
package extension ServerObjectID {
    var isExist: Bool {
        Manager.container[self] != nil
    }
    var ref: Object? {
        Manager.container[self]
    }
}



// MARK: BudServerObjectManager
@BudServer
package protocol ServerObjectManager: AnyObject, Sendable {
    associatedtype Object: ServerObject
    static var container: [Object.ID: Object] { get set }
}

@BudServer
package extension ServerObjectManager {
    static func register(_ object: Object) {
        container[object.id] = object
    }
    static func unregister(_ id: Object.ID) {
        container[id] = nil
    }
}

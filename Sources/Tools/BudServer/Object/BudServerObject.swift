//
//  BudServerObject.swift
//  BudClient
//
//  Created by 김민우 on 7/2/25.
//
import Foundation


// MARK: BudServerObject
@BudServer
package protocol BudServerObject: AnyObject, Sendable {
    associatedtype ID: BudServerObjectID where ID.Object == Self
    nonisolated var id: ID { get }
}


// MARK: BudObjectID
@BudServer
package protocol BudServerObjectID: Sendable, Hashable {
    associatedtype Object: BudServerObject where Object.ID == Self
    associatedtype Manager: BudServerObjectManager where Manager.Object == Object
    var value: UUID { get }
}

@BudServer
package extension BudServerObjectID {
    var isExist: Bool {
        Manager.container[self] != nil
    }
    var ref: Object? {
        Manager.container[self]
    }
}



// MARK: BudServerObjectManager
@BudServer
package protocol BudServerObjectManager: AnyObject, Sendable {
    associatedtype Object: BudServerObject
    static var container: [Object.ID: Object] { get set }
}

@BudServer
package extension BudServerObjectManager {
    static func register(_ object: Object) {
        container[object.id] = object
    }
    static func unregister(_ id: Object.ID) {
        container[id] = nil
    }
}

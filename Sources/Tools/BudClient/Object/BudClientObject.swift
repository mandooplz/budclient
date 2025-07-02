//
//  BudClientObject.swift
//  BudClient
//
//  Created by 김민우 on 7/2/25.
//
import Foundation


// MARK: BudServerObject
@MainActor
package protocol BudClientObject: AnyObject, Sendable {
    associatedtype ID: BudClientObjectID where ID.Object == Self
    nonisolated var id: ID { get }
}


// MARK: BudObjectID
@MainActor
package protocol BudClientObjectID: Sendable, Hashable {
    associatedtype Object: BudClientObject where Object.ID == Self
    associatedtype Manager: BudClientObjectManager where Manager.Object == Object
    var value: UUID { get }
}

@MainActor
package extension BudClientObjectID {
    var isExist: Bool {
        Manager.container[self] != nil
    }
    var ref: Object? {
        Manager.container[self]
    }
}



// MARK: BudServerObjectManager
@MainActor
package protocol BudClientObjectManager : AnyObject, Sendable {
    associatedtype Object: BudClientObject
    static var container: [Object.ID: Object] { get set }
}

@MainActor
package extension BudClientObjectManager {
    static func register(_ object: Object) {
        container[object.id] = object
    }
    static func unregister(_ id: Object.ID) {
        container[id] = nil
    }
}


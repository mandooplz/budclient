//
//  SystemSourceEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//


// MARK: SystemSourceEvent
package enum SystemSourceEvent: Sendable {
    case root(RootEvent)
    case object(ObjectEvent)
    
    package enum RootEvent: Sendable {
        case created(RootSourceID, ObjectID)
        case modified(RootSourceDiff)
        case deleted(RootSourceID)
    }
    
    package enum ObjectEvent: Sendable {
        case added(ObjectSourceID, ObjectID)
        case modified(ObjectSourceDiff)
        case removed(ObjectID)
    }
}



// MARK: RootSourceDiff
package struct RootSourceDiff: Sendable {
    package let name: String
}


// MARK: ObjectSourceDiff
package struct ObjectSourceDiff: Sendable {
    package let target: ObjectID
    package let name: String
}

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
        case created(RootSourceDiff)
        case modified(RootSourceDiff)
        case deleted(RootSourceDiff)
    }
    
    package enum ObjectEvent: Sendable {
        case added(ObjectSourceDiff)
        case modified(ObjectSourceDiff)
        case removed(ObjectSourceDiff)
    }
}



// MARK: RootSourceDiff
package struct RootSourceDiff: Sendable {
    package let id: RootSourceID
    package let target: ObjectID
    package let name: String
}


// MARK: ObjectSourceDiff
package struct ObjectSourceDiff: Sendable {
    package let id: ObjectSourceID
    package let target: ObjectID
    package let name: String
}

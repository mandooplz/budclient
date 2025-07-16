//
//  SystemSourceEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: SystemSourceEvent
package enum SystemSourceEvent: Sendable {
    case modified(SystemSourceDiff)
    case removed(SystemSourceDiff)
    
    case objectAdded(ObjectSourceDiff)
    case flowAdded(FlowSourceDiff)
}


// MARK: SystemSourceDiff
package struct SystemSourceDiff: Sendable {
    package let id: any SystemSourceIdentity
    package let target: SystemID
    package let name: String
    package let location: Location
    
    package init(id: any SystemSourceIdentity, target: SystemID, name: String, location: Location) {
        self.id = id
        self.target = target
        self.name = name
        self.location = location
    }
}

extension SystemSourceDiff {
    @Server
    init(_ object: SystemSourceMock) {
        self.id = object.id
        self.target = object.target
        self.name = object.name
        self.location = object.location
    }
    
    init?(from data: SystemSource.Data) {
        guard let id = data.id else { return nil}
        
        self.id = SystemSource.ID(id)
        self.target = data.target
        self.name = data.name
        self.location = data.location
    }
}




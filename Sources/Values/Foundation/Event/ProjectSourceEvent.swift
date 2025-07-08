//
//  ProjectEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: ProjectEvent
package enum ProjectSourceEvent: Sendable {
    case added(SystemSourceID, SystemID)
    case modified(SystemSourceDiff)
    case removed(SystemID)
    
    package struct Data {
        package let name: String
        
        package init(name: String) {
            self.name = name
        }
    }
}


// MARK: SystemSourceDiff
package struct SystemSourceDiff: Sendable {
    package let target: SystemID
    package let name: String
    package let location: Location
    
    package init(target: SystemID, name: String, location: Location) {
        self.target = target
        self.name = name
        self.location = location
    }
    
    package func getEvent() -> ProjectSourceEvent {
        .modified(self)
    }
}

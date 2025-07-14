//
//  SystemSourceDiff.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package struct SystemSourceDiff: Sendable {
    package let id: any SystemSourceIdentity
    package let target: SystemID
    package let name: String
    package let location: Location
    
    package let rootSource: RootSourceDiff
    
    package init(id: any SystemSourceIdentity, target: SystemID, name: String, location: Location, rootSource: RootSourceDiff) {
        self.id = id
        self.target = target
        self.name = name
        self.location = location
        self.rootSource = rootSource
    }
}

extension SystemSourceDiff {
    @Server
    init(_ object: SystemSourceMock) {
        self.id = object.id
        self.target = object.target
        self.name = object.name
        self.location = object.location
        
        let rootSourceRef = object.rootSourceRef
        self.rootSource = .init(
            id: rootSourceRef.id,
            target: rootSourceRef.target,
            name: rootSourceRef.name)
    }
    
    init?(from data: SystemSource.Data) {
        guard let id = data.id else { return nil}
        
        self.id = SystemSource.ID(id)
        self.target = data.target
        self.name = data.name
        self.location = data.location
        
        let rootSource = data.rootSource
        self.rootSource = .init(
            id: RootSource.ID(rootSource.id),
            target: rootSource.target,
            name: rootSource.name)
    }
}

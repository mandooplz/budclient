//
//  DB.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//


// MARK: DB
struct ProjectSources {
    static let name = "ProjectSources"
    private init() { }
    
    struct SystemSources {
        static let name = "SystemSources"
        private init() { }
        
        struct RootSources {
            static let name = "RootSources"
            private init() { }
        }
        
        struct ObjectSources {
            static let name = "ObjectSources"
            private init() { }
        }
    }
    
    struct ValueSources {
        static let name = "ValueSources"
        private init() { }
    }
}

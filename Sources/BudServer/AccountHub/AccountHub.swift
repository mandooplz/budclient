//
//  AccountHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServerMock


// MARK: Link
public struct AccountHubLink: Sendable {
    // MARK: core
    private nonisolated let mode: SystemMode
    public init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    public func isExist(email: String, password: String) async throws -> Bool {
        switch mode {
        case .test:
            await AccountHubMock.shared.isExist(email: email, password: password)
        case .real:
            fatalError()
        }
    }
    public func getUserId(email: String, password: String) async throws -> String? {
        switch mode {
        case .test:
            await AccountHubMock.shared.getUserId(email: email, password: password)
        case .real:
            fatalError()
        }
    }
    
    public func insertTicket(_ ticket: Ticket) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let ticketForMock = AccountHubMock.Ticket(value: ticket.value)
                AccountHubMock.shared.tickets.insert(ticketForMock)
            }
        case .real:
            fatalError()
        }
    }
    public func getRegisterForm(_ ticket: Ticket) async throws -> RegisterFormLink? {
        switch mode {
        case .test:
            let registerForm = await MainActor.run {
                AccountHubMock.shared.registerForms[ticket.forMock]
            }
            guard let registerForm else { return nil }
            return RegisterFormLink(mode: self.mode,
                                    idForMock: registerForm)
            
        case .real:
            fatalError()
        }
    }
    
    
    // MARK: action
    public func generateForms() async throws {
        switch mode {
        case .test:
            await AccountHubMock.shared.generateForms()
        case .real:
            fatalError()
        }
    }
    
    
    // MARK: value
    public struct Ticket: Sendable, Hashable {
        public let value: UUID
        public init(value: UUID = UUID()) {
            self.value = value
        }
        
        fileprivate var forMock: AccountHubMock.Ticket {
            AccountHubMock.Ticket(value: self.value)
        }
    }
}

//
//  AccountHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Link
public struct AccountHubLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    internal init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    public func isExist(email: String, password: String) async throws -> Bool {
        switch mode {
        case .test:
            await AccountHubMock.shared.isExist(email: email, password: password)
        case .real:
            try await AccountHub.shared.isExist(email: email, password: password)
        }
    }
    public func getUserId(email: String, password: String) async throws -> String {
        switch mode {
        case .test:
            do {
                return try await AccountHubMock.shared.getUserId(email: email, password: password)
            } catch(let error as AccountHubMock.Error) {
                switch error {
                case .userNotFound: throw Error.userNotFound;
                case .wrongPassword: throw Error.wrongPassword
                }
            } catch {
                throw error
            }
        case .real:
            do {
                return try await AccountHub.shared.getUserId(email: email, password: password)
            } catch(let error as AccountHubMock.Error) {
                switch error {
                case .userNotFound: throw Error.userNotFound;
                case .wrongPassword: throw Error.wrongPassword
                }
            } catch {
                throw error
            }
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
            await Server.run {
                let realTicket = AccountHub.Ticket(value: ticket.value)
                AccountHub.shared.tickets.insert(realTicket)
            }
        }
    }
    public func getRegisterForm(_ ticket: Ticket) async throws -> RegisterFormLink? {
        switch mode {
        case .test:
            // test에는 RegisterFormLink를 제공
            let registerForm = await MainActor.run {
                AccountHubMock.shared.registerForms[ticket.forMock]
            }
            guard let registerForm else { return nil }
            return RegisterFormLink(mode: self.mode,
                                    idForMock: registerForm)
            
        case .real:
            let registerForm = await Server.run {
                AccountHub.shared.registerForms[ticket.forReal]
            }
            guard let registerForm else { return nil }
            return RegisterFormLink(mode: self.mode,
                                    id: .init(realId: registerForm))
        }
    }
    
    
    // MARK: action
    public func generateForms() async throws {
        switch mode {
        case .test:
            await AccountHubMock.shared.generateForms()
        case .real:
            await AccountHub.shared.generateForms()
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
        fileprivate var forReal: AccountHub.Ticket {
            AccountHub.Ticket(value: self.value)
        }
    }
    public enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}

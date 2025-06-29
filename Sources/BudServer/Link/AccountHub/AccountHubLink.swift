//
//  AccountHubLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Link
package struct AccountHubLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    internal init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    package func isExist(email: String, password: String) async throws -> Bool {
        switch mode {
        case .test:
            await AccountHubMock.shared.isExist(email: email, password: password)
        case .real:
            try await AccountHub.shared.isExist(email: email, password: password)
        }
    }
    package func getUserId(email: String, password: String) async throws -> String {
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
    
    package func insertEmailTicket(_ ticket: Ticket) async throws {
        switch mode {
        case .test:
            let _ = await MainActor.run {
                AccountHubMock.shared.emailTickets.insert(ticket.forMock)
            }
        case .real:
            await Server.run {
                AccountHub.shared.emailTickets.insert(ticket.forReal)
            }
        }
    }
    package func getEmailRegisterForm(_ ticket: Ticket) async throws -> EmailRegisterFormLink? {
        switch mode {
        case .test:
            // test에는 RegisterFormLink를 제공
            let registerForm = await MainActor.run {
                AccountHubMock.shared.emailRegisterForms[ticket.forMock]
            }
            guard let registerForm else { return nil }
            return EmailRegisterFormLink(mode: self.mode,
                                    idForMock: registerForm)
            
        case .real:
            let registerForm = await Server.run {
                AccountHub.shared.emailRegisterForms[ticket.forReal]
            }
            guard let registerForm else { return nil }
            return EmailRegisterFormLink(mode: self.mode,
                                    id: .init(realId: registerForm))
        }
    }
    
    package func insertGoogleTicket(_ ticket: Ticket) async throws {
        switch mode {
        case .test:
            let _ = await MainActor.run {
                AccountHubMock.shared.googleTickets.insert(ticket.forMock)
            }
        case .real:
            await Server.run {
                AccountHub.shared.googleTickets.insert(ticket.forReal)
            }
        }
    }
    package func getGoogleRegisterForm(_ ticket: Ticket) async throws {
        
    }
    
    
    // MARK: action
    package func updateEmailForms() async throws {
        switch mode {
        case .test:
            await AccountHubMock.shared.updateEmailForms()
        case .real:
            await AccountHub.shared.updateEmailForms()
        }
    }
    package func updateGoogleForms() async throws {
        switch mode {
        case .test:
            await AccountHubMock.shared.updateGoogleForms()
        case .real:
            await AccountHub.shared.updateGoogleForms()
        }
    }
    
    
    // MARK: value
    package struct Ticket: Sendable, Hashable {
        package let value: UUID
        package init(value: UUID = UUID()) {
            self.value = value
        }
        
        fileprivate var forMock: AccountHubMock.Ticket {
            AccountHubMock.Ticket(value: self.value)
        }
        fileprivate var forReal: AccountHub.Ticket {
            AccountHub.Ticket(value: self.value)
        }
    }
    package enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}

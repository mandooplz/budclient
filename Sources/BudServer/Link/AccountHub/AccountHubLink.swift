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
    package func getUserId(idToken: String, accessToken: String) async throws -> String {
        switch mode {
        case .test:
            guard let userId = await AccountHubMock.shared.getUserId(googleIdToken: idToken,
                                                                     googleAccessToken: accessToken) else {
                throw Error.userNotFound
            }
            return userId
        case .real:
            let userId = try await AccountHub.shared.getUserId(googleIdToken: idToken,googleAccessToken: accessToken)
            return userId
        }
    }
    
    package func insertEmailTicket(_ ticket: Ticket) async {
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
    package func getEmailRegisterForm(_ ticket: Ticket) async -> EmailRegisterFormLink? {
        switch mode {
        case .test:
            let emailRegisterForm = await MainActor.run {
                AccountHubMock.shared.emailRegisterForms[ticket.forMock]
            }
            guard let emailRegisterForm else { return nil }
            return .init(mode: .test(mock: emailRegisterForm))
            
        case .real:
            let emailRegisterForm = await Server.run {
                AccountHub.shared.emailRegisterForms[ticket.forReal]
            }
            guard let emailRegisterForm else { return nil }
            return .init(mode: .real(object: emailRegisterForm))
        }
    }
    
    package func insertGoogleTicket(_ ticket: Ticket) async {
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
    package func getGoogleRegisterForm(_ ticket: Ticket) async -> GoogleRegisterFormLink? {
        switch mode {
        case .test:
            return await MainActor.run {
                guard let googleRegisterForm = AccountHubMock.shared.googleRegisterForms[ticket.forMock] else {
                    return nil
                }
                return .init(mode: .test(mock: googleRegisterForm))
            }
        case .real:
            return await Server.run {
                guard let googleRegisterForm = AccountHub.shared.googleRegisterForms[ticket.forReal] else {
                    return nil
                }
                return .init(mode: .real(object: googleRegisterForm))
            }
        }
    }
    
    
    // MARK: action
    package func updateEmailForms() async {
        switch mode {
        case .test:
            await AccountHubMock.shared.updateEmailForms()
        case .real:
            await AccountHub.shared.updateEmailForms()
        }
    }
    package func updateGoogleForms() async {
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

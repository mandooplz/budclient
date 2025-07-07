//
//  CommunityTests.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("Community")
struct CommunityTests {
    
}



// MARK: Helphers
private func getCommunity(_ budClientRef: BudClient) async -> Community {
    await signIn(budClientRef)
    
    let community = await budClientRef.community!
    return await community.ref!
}

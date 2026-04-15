//
//  MedCertifyTests.swift
//  MedCertifyTests
//
//  Created by Rork on March 3, 2026.
//

import Testing
import Foundation
@testable import MedCertify

struct MedCertifyTests {
    @Test func educationLabelsChangeByProfession() {
        let physician = UserProfile(profession: "Physician (MD/DO)", name: "Avery Stone")
        let nurse = UserProfile(profession: "Nurse (RN/NP/APRN)", name: "Jordan Fields")

        #expect(physician.educationTabTitle == "CME")
        #expect(nurse.educationTabTitle == "CE")
        #expect(physician.educationLongTitle == "Continuing Medical Education")
        #expect(nurse.educationLongTitle == "Continuing Education")
    }

    @Test func urgencyRankingPrefersExpiredThenExpiring() {
        let expired = Credential(
            type: CredentialType.stateLicense.rawValue,
            name: "Expired License",
            expirationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
        )
        let expiring = Credential(
            type: CredentialType.boardCertification.rawValue,
            name: "Expiring Board",
            expirationDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())
        )
        let current = Credential(
            type: CredentialType.npi.rawValue,
            name: "Current NPI",
            expirationDate: Calendar.current.date(byAdding: .day, value: 220, to: Date())
        )

        #expect(expired.urgencyRank < expiring.urgencyRank)
        #expect(expiring.urgencyRank < current.urgencyRank)
        #expect(expired.dueStatusText.contains("Expired"))
    }

    @Test func workflowSummaryUsesTrackingMethod() {
        let profile = UserProfile(
            profession: "Pharmacist",
            name: "Morgan Lee",
            currentTrackingMethod: "a spreadsheet"
        )

        #expect(profile.firstNameOrFallback == "Morgan")
        #expect(profile.workflowSourceLabel.contains("spreadsheet"))
    }

}

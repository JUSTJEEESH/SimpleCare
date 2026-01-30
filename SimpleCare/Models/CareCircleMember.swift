import Foundation
import SwiftData

@Model
final class CareCircleMember {
    var id: UUID
    var name: String
    var relationship: String
    var phoneNumber: String
    var isEmergencyContact: Bool
    var notifyOnMissedDose: Bool
    var createdAt: Date

    init(
        name: String = "",
        relationship: String = "Family",
        phoneNumber: String = "",
        isEmergencyContact: Bool = false,
        notifyOnMissedDose: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.isEmergencyContact = isEmergencyContact
        self.notifyOnMissedDose = notifyOnMissedDose
        self.createdAt = Date()
    }

    static let relationships = [
        "Spouse",
        "Son",
        "Daughter",
        "Sibling",
        "Friend",
        "Caregiver",
        "Nurse",
        "Doctor",
        "Other"
    ]
}

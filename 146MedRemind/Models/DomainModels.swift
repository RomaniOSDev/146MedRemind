//
//  DomainModels.swift
//  146MedRemind
//

import Foundation
import SwiftUI

enum DosageUnit: String, CaseIterable, Codable {
    case mg = "mg"
    case g = "g"
    case mcg = "mcg"
    case ml = "mL"
    case tablet = "tab."
    case capsule = "caps."
    case drop = "drops"
    case puff = "puff"
    case unit = "units"
}

enum FrequencyType: String, CaseIterable, Codable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case custom = "Custom schedule"
}

enum DayOfWeek: Int, CaseIterable, Codable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

enum SkipReason: String, CaseIterable, Codable {
    case forgot = "Forgot"
    case ranOut = "Out of stock"
    case sideEffects = "Side effects"
    case other = "Other"
}

enum HistoryDoseFilter: String, CaseIterable {
    case all = "All"
    case taken = "Taken"
    case missed = "Missed"
    case skipped = "Skipped"
}

struct Medication: Identifiable, Equatable {
    let id: UUID
    var name: String
    var dosage: Double
    var unit: DosageUnit
    var instructions: String?
    var notes: String?
    var isActive: Bool
    var refillDate: Date?
    var refillReminder: Bool
    let createdAt: Date
    /// When non-nil, each “taken” dose subtracts one unit from this count.
    var stockCount: Int?
    /// Alert when `stockCount` is at or below this value (only when tracking stock).
    var lowStockThreshold: Int
    /// Archived medications are hidden from Today and do not receive dose reminders.
    var isArchived: Bool
}

extension Medication: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, dosage, unit, instructions, notes, isActive, refillDate, refillReminder, createdAt
        case stockCount, lowStockThreshold, isArchived
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        dosage = try c.decode(Double.self, forKey: .dosage)
        unit = try c.decode(DosageUnit.self, forKey: .unit)
        instructions = try c.decodeIfPresent(String.self, forKey: .instructions)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        refillDate = try c.decodeIfPresent(Date.self, forKey: .refillDate)
        refillReminder = try c.decode(Bool.self, forKey: .refillReminder)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        stockCount = try c.decodeIfPresent(Int.self, forKey: .stockCount)
        lowStockThreshold = try c.decodeIfPresent(Int.self, forKey: .lowStockThreshold) ?? 7
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(dosage, forKey: .dosage)
        try c.encode(unit, forKey: .unit)
        try c.encodeIfPresent(instructions, forKey: .instructions)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encode(isActive, forKey: .isActive)
        try c.encodeIfPresent(refillDate, forKey: .refillDate)
        try c.encode(refillReminder, forKey: .refillReminder)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(stockCount, forKey: .stockCount)
        try c.encode(lowStockThreshold, forKey: .lowStockThreshold)
        try c.encode(isArchived, forKey: .isArchived)
    }
}

struct Schedule: Identifiable, Codable, Equatable {
    let id: UUID
    var medicationId: UUID
    var medicationName: String
    var times: [Date]
    var frequency: FrequencyType
    var daysOfWeek: [DayOfWeek]?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
}

struct Dose: Identifiable, Codable, Equatable {
    let id: UUID
    let medicationId: UUID
    var medicationName: String
    let scheduledTime: Date
    var takenTime: Date?
    var dosage: Double
    var unit: DosageUnit
    var notes: String?
    var isSkipped: Bool
    var skipReason: SkipReason?

    var status: DoseStatus {
        if isSkipped {
            return .skipped
        } else if takenTime != nil {
            return .taken
        } else if scheduledTime < Date() {
            return .missed
        } else {
            return .pending
        }
    }
}

enum DoseStatus: Equatable {
    case pending
    case taken
    case missed
    case skipped

    var color: Color {
        switch self {
        case .pending: return .medPending
        case .taken: return .medTaken
        case .missed: return .red
        case .skipped: return Color.medTertiaryLabel
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .taken: return "checkmark.circle.fill"
        case .missed: return "exclamationmark.circle.fill"
        case .skipped: return "xmark.circle.fill"
        }
    }
}

struct Refill: Identifiable, Codable, Equatable {
    let id: UUID
    let medicationId: UUID
    let medicationName: String
    let date: Date
    let quantity: Int
    let notes: String?
}

struct Prescriber: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var specialty: String?
    var phone: String?
    var clinic: String?
}

//
//  MedDateFormatting.swift
//  146MedRemind
//

import Foundation

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let mediumDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    f.locale = Locale(identifier: "en_US")
    return f
}()

private let shortDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MM/dd/yyyy"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

func formattedTime(_ date: Date) -> String {
    timeFormatter.string(from: date)
}

func formattedDate(_ date: Date) -> String {
    mediumDateFormatter.string(from: date)
}

func formattedShortDate(_ date: Date) -> String {
    shortDateFormatter.string(from: date)
}

func statusText(_ status: DoseStatus) -> String {
    switch status {
    case .pending: return "Pending"
    case .taken: return "Taken"
    case .missed: return "Missed"
    case .skipped: return "Skipped"
    }
}

func skipReasonLine(_ dose: Dose) -> String? {
    guard dose.isSkipped, let reason = dose.skipReason else { return nil }
    return reason.rawValue
}

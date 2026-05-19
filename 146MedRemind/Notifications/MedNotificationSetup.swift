//
//  MedNotificationSetup.swift
//  146MedRemind
//

import Foundation
import UserNotifications

enum MedNotificationSetup {
    static let doseReminderCategoryId = "MED_DOSE_REMINDER"
    static let snooze10ActionId = "MED_SNOOZE_10"
    static let snooze30ActionId = "MED_SNOOZE_30"

    static let userInfoMedicationIdKey = "medicationId"
    static let userInfoMedicationNameKey = "medicationName"

    static func registerCategories() {
        let snooze10 = UNNotificationAction(
            identifier: snooze10ActionId,
            title: "Remind in 10 min",
            options: []
        )
        let snooze30 = UNNotificationAction(
            identifier: snooze30ActionId,
            title: "Remind in 30 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: doseReminderCategoryId,
            actions: [snooze10, snooze30],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Schedules a one-off reminder (snooze from notification action or in-app).
    static func scheduleSnoozeNotification(
        medicationId: UUID,
        medicationName: String,
        delaySeconds: TimeInterval
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Dose reminder"
        content.body = "Time to take \(medicationName)"
        content.sound = .default
        content.categoryIdentifier = doseReminderCategoryId
        content.userInfo = [
            userInfoMedicationIdKey: medicationId.uuidString,
            userInfoMedicationNameKey: medicationName
        ]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, delaySeconds), repeats: false)
        let id = "snooze-\(medicationId.uuidString)-\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

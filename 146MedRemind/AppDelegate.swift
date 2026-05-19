//
//  AppDelegate.swift
//  146MedRemind
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        MedNotificationSetup.registerCategories()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        let actionId = response.actionIdentifier
        guard actionId == MedNotificationSetup.snooze10ActionId || actionId == MedNotificationSetup.snooze30ActionId else {
            return
        }

        let delay: TimeInterval = actionId == MedNotificationSetup.snooze10ActionId ? 600 : 1800
        let userInfo = response.notification.request.content.userInfo
        guard
            let mid = userInfo[MedNotificationSetup.userInfoMedicationIdKey] as? String,
            let uuid = UUID(uuidString: mid),
            let name = userInfo[MedNotificationSetup.userInfoMedicationNameKey] as? String
        else {
            return
        }

        MedNotificationSetup.scheduleSnoozeNotification(
            medicationId: uuid,
            medicationName: name,
            delaySeconds: delay
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

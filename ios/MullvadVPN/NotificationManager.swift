//
//  NotificationManager.swift
//  MullvadVPN
//
//  Created by pronebird on 31/05/2021.
//  Copyright © 2021 Mullvad VPN AB. All rights reserved.
//

import Foundation
import UserNotifications
import Logging

enum NotificationRequestIdentifier {
    static let accountExpiry = "net.mullvad.MullvadVPN.AccountExpiryNotification"
}

class NotificationManager: AccountObserver {

    private lazy var logger = Logger(label: "NotificationManager")

    init() {
        Account.shared.addObserver(self)
    }

    func addAccountExpiryNotification(accountExpiry: Date) {
        requestNotificationPermissions { (granted) in
            guard granted else {
                return
            }

            guard let request = self.makeAccountExpiryNotificationRequest(accountExpiry: accountExpiry) else {
                return
            }

            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    self.logger.error("Failed to add account expiry notification request: \(error.localizedDescription)")
                }
            }
        }
    }

    private func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        let userNotificationCenter = UNUserNotificationCenter.current()

        userNotificationCenter.getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                userNotificationCenter.requestAuthorization(options: [.alert, .sound, .provisional]) { (granted, error) in
                    if let error = error {
                        self.logger.error("Failed to obtain user notifications authorization: \(error.localizedDescription)")
                    }
                    completion(granted)
                }

            case .authorized, .provisional:
                completion(true)

            case .denied, .ephemeral:
                fallthrough

            @unknown default:
                completion(false)
            }
        }
    }

    private func makeAccountExpiryNotificationRequest(accountExpiry: Date) -> UNNotificationRequest? {
        // Subtract 3 days from expiry date
        guard let absoluteTriggerDate = Calendar.current.date(byAdding: .day, value: -3, to: accountExpiry) else { return nil }

        // Do not produce notification if less than 3 days left till expiry
        guard absoluteTriggerDate > Date() else { return nil }

        // Set time to 9am
        guard let triggerDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: absoluteTriggerDate) else { return nil }

        let content = UNMutableNotificationContent()
        content.body = NSString.localizedUserNotificationString(forKey: "AccountExpiryNotificationBody", arguments: nil)
        content.sound = UNNotificationSound.default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second, .day, .month, .year], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: NotificationRequestIdentifier.accountExpiry,
            content: content,
            trigger: trigger
        )
    }

    // MARK: - AccountObserver

    func account(_ account: Account, didUpdateExpiry expiry: Date) {
        addAccountExpiryNotification(accountExpiry: expiry)
    }

    func account(_ account: Account, didLoginWithToken token: String, expiry: Date) {
        addAccountExpiryNotification(accountExpiry: expiry)
    }

    func accountDidLogout(_ account: Account) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationRequestIdentifier.accountExpiry]
        )
    }
}

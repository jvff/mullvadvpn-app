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
import UIKit

let kAccountExpiryNotificationIdentifier = "net.mullvad.MullvadVPN.AccountExpiryNotification"

class NotificationManager: AccountObserver {

    private lazy var logger = Logger(label: "NotificationManager")

    init() {
        Account.shared.addObserver(self)
    }

    func processNotifications() {

    }

    private func addAccountExpiryNotification(accountExpiry: Date) {
        requestNotificationPermissions { (granted) in
            guard let triggerDate = self.triggerDateForAccountExpiryNotification(accountExpiry: accountExpiry), granted else {
                return
            }

            UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingRequests) in
                let hasPendingAccountExpiryNotification = pendingRequests.contains(where: { (pendingRequest) in
                    let calendarTrigger = pendingRequest.trigger as? UNCalendarNotificationTrigger

                    return pendingRequest.identifier == kAccountExpiryNotificationIdentifier &&
                        calendarTrigger?.nextTriggerDate() == triggerDate
                })

                guard !hasPendingAccountExpiryNotification else { return }

                let request = self.makeAccountExpiryNotificationRequest(triggerDate: triggerDate)

                UNUserNotificationCenter.current().add(request) { (error) in
                    if let error = error {
                        self.logger.error("Failed to add account expiry notification request: \(error.localizedDescription)")
                    }
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

    private func triggerDateForAccountExpiryNotification(accountExpiry: Date) -> Date? {
        // Subtract 3 days from expiry date
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: accountExpiry) else { return nil }

        // Do not produce notification if less than 3 days left till expiry
        guard triggerDate > Date() else { return nil }

        // Set time to 9am
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: triggerDate)
    }

    private func makeAccountExpiryNotificationRequest(triggerDate: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.body = NSString.localizedUserNotificationString(forKey: "AccountExpiryNotificationBody", arguments: nil)
        content.sound = UNNotificationSound.default

        let dateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        return UNNotificationRequest(
            identifier: kAccountExpiryNotificationIdentifier,
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
            withIdentifiers: [kAccountExpiryNotificationIdentifier]
        )
    }
}

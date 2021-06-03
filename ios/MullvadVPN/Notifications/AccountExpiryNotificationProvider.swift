//
//  AccountExpiryNotificationProvider.swift
//  MullvadVPN
//
//  Created by pronebird on 03/06/2021.
//  Copyright © 2021 Mullvad VPN AB. All rights reserved.
//

import Foundation
import UserNotifications

class AccountExpiryNotificationProvider: NotificationProvider, SystemNotificationProvider, InAppNotificationProvider, AccountObserver {
    private var _accountExpiry: Date?
    private var accountExpiry: Date? {
        set {
            _accountExpiry = Date().addingTimeInterval(24 * 3600 * 3)
        }
        get {
            return _accountExpiry
        }
    }

    override var identifier: String {
        return kAccountExpiryNotificationIdentifier
    }

    override init() {
        super.init()
        accountExpiry = Account.shared.expiry
    }

    // MARK: - SystemNotificationProvider

    var trigger: UNNotificationTrigger? {
        guard let accountExpiry = accountExpiry else { return nil }

        // Subtract 3 days from expiry date
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: accountExpiry) else { return nil }

        // Do not produce notification if less than 3 days left till expiry
        guard triggerDate > Date() else { return nil }

        // Set time to 9am
        guard let triggerDateWithTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: triggerDate) else { return nil }

        let dateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: triggerDateWithTime)

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }

    var notificationRequest: UNNotificationRequest? {
        guard let trigger = trigger else { return nil }

        let content = UNMutableNotificationContent()
        content.body = NSString.localizedUserNotificationString(forKey: "ACCOUNT_EXPIRY_SYSTEM_NOTIFICATION_BODY", arguments: nil)
        content.sound = UNNotificationSound.default

        return UNNotificationRequest(
            identifier: kAccountExpiryNotificationIdentifier,
            content: content,
            trigger: trigger
        )
    }

    var shouldRemovePendingRequests: Bool {
        // Remove pending notifications when account expiry is not set (user logged out)
        return accountExpiry == nil
    }

    var shouldRemoveDeliveredRequests: Bool {
        // Remove delivered notifications when account expiry is not set (user logged out)
        return accountExpiry == nil
    }

    // MARK: - InAppNotificationProvider

    var notificationDescriptor: InAppNotificationDescriptor? {
        guard let accountExpiry = accountExpiry else { return nil }

        // Subtract 3 days from expiry date
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: accountExpiry) else { return nil }

        // Only produce in-app notification within the last 3 days till expiry
        guard triggerDate < Date() || triggerDate > accountExpiry else { return nil }

        // Format the remaining duration
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.maximumUnitCount = 1

        guard let duration = formatter.string(from: Date(), to: accountExpiry) else { return nil }

        return InAppNotificationDescriptor(
            identifier: self.identifier,
            style: .warning,
            title: NSLocalizedString("ACCOUNT_EXPIRY_INAPP_NOTIFICATION_TITLE", comment: ""),
            body: String(format: NSLocalizedString("ACCOUNT_EXPIRY_INAPP_NOTIFICATION_BODY", comment: ""), duration)
        )
    }

    func account(_ account: Account, didUpdateExpiry expiry: Date) {
        self.accountExpiry = expiry
        invalidate()
    }

    func account(_ account: Account, didLoginWithToken token: String, expiry: Date) {
        self.accountExpiry = expiry
        invalidate()
    }

    func accountDidLogout(_ account: Account) {
        self.accountExpiry = nil
        invalidate()
    }

}

//
//  InAppNotificationController.swift
//  MullvadVPN
//
//  Created by pronebird on 01/06/2021.
//  Copyright © 2021 Mullvad VPN AB. All rights reserved.
//

import UIKit

struct InAppNotification {
    var style: InAppNotificationStyle
    var title: String
    var body: String
}

class InAppNotificationController {
    let containerView: UIView
    let bannerView: InAppNotificationBannerView

    private let showBannerConstraint: NSLayoutConstraint
    private let hideBannerConstraint: NSLayoutConstraint

    init(containerView: UIView) {
        self.containerView = containerView
        self.bannerView = InAppNotificationBannerView()
        self.bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.bannerView.isHidden = true

        containerView.addSubview(self.bannerView)

        showBannerConstraint = self.bannerView.topAnchor.constraint(equalTo: containerView.topAnchor)
        hideBannerConstraint = self.bannerView.bottomAnchor.constraint(equalTo: containerView.topAnchor)

        NSLayoutConstraint.activate([
            hideBannerConstraint,
            self.bannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            self.bannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
    }

    func toggleBanner(show: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        if show {
            self.bannerView.isHidden = false
            self.hideBannerConstraint.isActive = false
            self.showBannerConstraint.isActive = true
        } else {
            self.showBannerConstraint.isActive = false
            self.hideBannerConstraint.isActive = true
        }

        let finish = {
            if !show {
                self.bannerView.isHidden = true
            }
            completion?()
        }

        if animated {
            let timing = UISpringTimingParameters(dampingRatio: 0.7, initialVelocity: CGVector(dx: 0, dy: 1))
            let animator = UIViewPropertyAnimator(duration: 0.8, timingParameters: timing)

            animator.addAnimations {
                self.containerView.layoutIfNeeded()
            }
            animator.isInterruptible = false
            animator.addCompletion { _ in
                finish()
            }

            animator.startAnimation()
        } else {
            containerView.layoutIfNeeded()
            finish()
        }
    }

    func setNotification(_ notification: InAppNotification) {
        bannerView.title = notification.title
        bannerView.body = notification.body
        bannerView.style = notification.style
    }
}

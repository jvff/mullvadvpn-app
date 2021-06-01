//
//  InAppNotificationBannerView.swift
//  MullvadVPN
//
//  Created by pronebird on 01/06/2021.
//  Copyright © 2021 Mullvad VPN AB. All rights reserved.
//

import UIKit

enum InAppNotificationStyle {
    case success, warning, error

    fileprivate var color: UIColor {
        switch self {
        case .success:
            return UIColor.InAppNotificationBanner.successIndicatorColor
        case .warning:
            return UIColor.InAppNotificationBanner.warningIndicatorColor
        case .error:
            return UIColor.InAppNotificationBanner.errorIndicatorColor
        }
    }
}

class InAppNotificationBannerView: UIView {

    private static let indicatorViewSize = CGSize(width: 12, height: 12)

    private let backgroundView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: effect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    private let titleLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        return textLabel
    }()

    private let bodyLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = UIFont.systemFont(ofSize: 17)
        textLabel.textColor = UIColor(white: 1, alpha: 0.6)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        return textLabel
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .dangerColor
        view.layer.cornerRadius = InAppNotificationBannerView.indicatorViewSize.width * 0.5
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .circular
        }
        return view
    }()

    private let wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layoutMargins = UIMetrics.inAppBannerNotificationLayoutMargins
        view.preservesSuperviewLayoutMargins = true
        return view
    }()

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var body: String? {
        didSet {
            bodyLabel.text = body
        }
    }

    var style: InAppNotificationStyle = .error {
        didSet {
            indicatorView.backgroundColor = style.color
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        for subview in [titleLabel, bodyLabel, indicatorView] {
            wrapperView.addSubview(subview)
        }

        backgroundView.contentView.addSubview(wrapperView)
        addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            wrapperView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            wrapperView.leadingAnchor.constraint(equalTo: backgroundView.contentView.leadingAnchor),
            wrapperView.trailingAnchor.constraint(equalTo: backgroundView.contentView.trailingAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor),

            indicatorView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            indicatorView.leadingAnchor.constraint(equalTo: wrapperView.layoutMarginsGuide.leadingAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: Self.indicatorViewSize.width),
            indicatorView.heightAnchor.constraint(equalToConstant: Self.indicatorViewSize.height),

            titleLabel.topAnchor.constraint(equalTo: wrapperView.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: indicatorView.trailingAnchor, multiplier: 1),
            titleLabel.trailingAnchor.constraint(equalTo: wrapperView.layoutMarginsGuide.trailingAnchor),

            bodyLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(equalTo: wrapperView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

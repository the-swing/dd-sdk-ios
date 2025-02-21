/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation
#if os(iOS)
import DatadogSessionReplay

/// An entry point to Datadog Session Replay feature.
@objc
public final class DDSessionReplay: NSObject {
    override private init() { }

    /// Enables Datadog Session Replay feature.
    ///
    /// Recording will start automatically after enabling Session Replay.
    ///
    /// Note: Session Replay requires the RUM feature to be enabled.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of the feature.
    @objc
    public static func enable(with configuration: DDSessionReplayConfiguration) {
        SessionReplay.enable(with: configuration._swift)
    }
}

/// Session Replay feature configuration.
@objc
public final class DDSessionReplayConfiguration: NSObject {
    internal var _swift: SessionReplay.Configuration = .init(replaySampleRate: 0)

    /// The sampling rate for Session Replay. It is applied in addition to the RUM session sample rate.
    ///
    /// It must be a number between 0.0 and 100.0, where 0 means no replays will be recorded
    /// and 100 means all RUM sessions will contain replay.
    ///
    /// Note: This sample rate is applied in addition to the RUM sample rate. For example, if RUM uses a sample rate of 80%
    /// and Session Replay uses a sample rate of 20%, it means that out of all user sessions, 80% will be included in RUM,
    /// and within those sessions, only 20% will have replays.
    @objc public var replaySampleRate: Float {
        set { _swift.replaySampleRate = newValue }
        get { _swift.replaySampleRate }
    }

    /// Defines the way sensitive content (e.g. text) should be masked.
    ///
    /// Default: `.mask`.
    @objc public var defaultPrivacyLevel: DDSessionReplayConfigurationPrivacyLevel {
        set { _swift.defaultPrivacyLevel = newValue._swift }
        get { .init(_swift.defaultPrivacyLevel) }
    }

    /// Custom server url for sending replay data.
    ///
    /// Default: `nil`.
    @objc public var customEndpoint: URL? {
        set { _swift.customEndpoint = newValue }
        get { _swift.customEndpoint }
    }

    /// Creates Session Replay configuration.
    ///
    /// - Parameters:
    ///   - replaySampleRate: The sampling rate for Session Replay. It is applied in addition to the RUM session sample rate.
    @objc
    public required init(
        replaySampleRate: Float
    ) {
        _swift = SessionReplay.Configuration(
            replaySampleRate: replaySampleRate
        )
        super.init()
    }
}

/// Available privacy levels for content masking.
@objc
public enum DDSessionReplayConfigurationPrivacyLevel: Int {
    /// Record all content.
    case allow

    /// Mask all content.
    case mask

    /// Mask input elements, but record all other content.
    case maskUserInput

    internal var _swift: SessionReplay.Configuration.PrivacyLevel {
        switch self {
        case .allow: return .allow
        case .mask: return .mask
        case .maskUserInput: return .maskUserInput
        default: return .mask
        }
    }

    internal init(_ swift: SessionReplay.Configuration.PrivacyLevel) {
        switch swift {
        case .allow: self = .allow
        case .mask: self = .mask
        case .maskUserInput: self = .maskUserInput
        }
    }
}

#endif

/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-Present Datadog, Inc.
*/

import UIKit
import DatadogCore
import DatadogLogs
import DatadogTrace
import DatadogRUM
import DatadogCrashReporting

let serviceName = "ios-sdk-example-app"

var logger: LoggerProtocol!
var tracer: OTTracer { Tracer.shared() }
var rumMonitor: RUMMonitorProtocol { RUMMonitor.shared() }

@UIApplicationMain
class ExampleAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if Environment.isRunningUnitTests() {
            return false
        }

        // Initialize Datadog SDK
        Datadog.initialize(
            with: Datadog.Configuration(
                clientToken: Environment.readClientToken(),
                env: "tests",
                service: serviceName,
                batchSize: .small,
                uploadFrequency: .frequent
            ),
            trackingConsent: .granted
        )

        // Set user information
        Datadog.setUserInfo(id: "abcd-1234", name: "foo", email: "foo@example.com", extraInfo: ["key-extraUserInfo": "value-extraUserInfo"])

        // Enable Logs
        Logs.enable(
            with: Logs.Configuration(
                customEndpoint: Environment.readCustomLogsURL()
            )
        )

        // Enable Crash Reporting
        CrashReporting.enable()

        // Set highest verbosity level to see debugging logs from the SDK
        Datadog.verbosityLevel = .debug

        // Enable Trace
        Trace.enable(
            with: Trace.Configuration(
                networkInfoEnabled: true,
                customEndpoint: Environment.readCustomTraceURL()
            )
        )

        // Enable RUM
        RUM.enable(
            with: RUM.Configuration(
                applicationID: Environment.readRUMApplicationID(),
                urlSessionTracking: .init(firstPartyHostsTracing: .trace(hosts: [], sampleRate: 100)),
                trackBackgroundEvents: true,
                customEndpoint: Environment.readCustomRUMURL(),
                telemetrySampleRate: 100
            )
        )
        RUMMonitor.shared().debug = true

        // Create Logger
        logger = Logger.create(
            with: Logger.Configuration(
                name: "logger-name",
                networkInfoEnabled: true,
                consoleLogFormat: .shortWith(prefix: "[iOS App] ")
            )
        )

        logger.addAttribute(forKey: "device-model", value: UIDevice.current.model)

        #if DEBUG
        logger.addTag(withKey: "build_configuration", value: "debug")
        #else
        logger.addTag(withKey: "build_configuration", value: "release")
        #endif

        // Launch initial screen depending on the launch configuration
        #if os(iOS)
        let storyboard = UIStoryboard(name: "Main iOS", bundle: nil)
        launch(storyboard: storyboard)
        #endif

        #if !os(tvOS)
        // Instantiate location monitor if the Example app is run in interactive mode. This will
        // enable background location tracking if it was started in previous session.
        if Environment.isRunningInteractive() {
            backgroundLocationMonitor = BackgroundLocationMonitor(rum: rumMonitor)
        }
        #endif

        return true
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func launch(storyboard: UIStoryboard) {
        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.makeKeyAndVisible()
        }
        window?.rootViewController = storyboard.instantiateInitialViewController()!
    }
}

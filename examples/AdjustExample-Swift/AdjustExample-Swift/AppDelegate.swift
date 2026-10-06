//
//  AppDelegate.swift
//  AdjustExample-Swift
//
//  Created by Uglješa Erceg (@uerceg) on 6th April 2016.
//  Copyright © 2016-Present Adjust GmbH. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AdjustDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let appToken = "2fm9gkqubvpc"
        let environment = ADJEnvironmentSandbox
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)

        // Change the log level.
        adjustConfig?.logLevel = ADJLogLevel.verbose

        // Set delegate object.
        adjustConfig?.delegate = self

        // Add global callback parameters.
        Adjust.addGlobalCallbackParameter("wan", forKey: "obi")
        Adjust.addGlobalCallbackParameter("yoda", forKey: "master")

        // Add global partner parameters.
        Adjust.addGlobalPartnerParameter("vader", forKey: "darth")
        Adjust.addGlobalPartnerParameter("solo", forKey: "han")

        // Remove global callback parameter.
        Adjust.removeGlobalCallbackParameter(forKey: "obi")
        // Remove global partner parameter.
        Adjust.removeGlobalPartnerParameter(forKey: "han")

        // Initialise the SDK.
        Adjust.initSdk(adjustConfig!)

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("Scheme based deep link opened an app: \(url.absoluteString)")
        // add your code below to handle deep link
        // (e.g., open deep link content)
        // url object contains the deep link

        // Call the below method to send deep link to Adjust backend
        Adjust.processDeeplink(ADJDeeplink(deeplink: url)!)
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
            print("Universal link opened an app: \(userActivity.webpageURL!.absoluteString)")
            // Pass deep link to Adjust in order to potentially reattribute user.
            Adjust.processDeeplink(ADJDeeplink(deeplink: userActivity.webpageURL!)!)
        }
        return true
    }

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        print("Attribution callback called!")
        print("Attribution: \(String(describing: attribution))")
    }

    func adjustThirdPartySharingSettingsChanged(_ thirdPartySharingResult: ADJThirdPartySharingResult?) {
        print("Third Party sharing callback called!")
        print("Third party sharing: \(thirdPartySharingResult?.thirdPartySharingSettingsJson ?? "")")
    }

    func adjustEventTrackingSucceeded(_ eventSuccessResponseData: ADJEventSuccess?) {
        print("Event success callback called!")
        print("Event success data: \(String(describing: eventSuccessResponseData))")
    }

    func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?) {
        print("Event failure callback called!")
        print("Event failure data: \(String(describing: eventFailureResponseData))")
    }

    func adjustSessionTrackingSucceeded(_ sessionSuccessResponseData: ADJSessionSuccess?) {
        print("Session success callback called!")
        print("Session success data: \(String(describing: sessionSuccessResponseData))")
    }

    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?) {
        print("Session failure callback called!")
        print("Session failure data: \(String(describing: sessionFailureResponseData))")
    }

    func adjustDeferredDeeplinkReceived(_ deeplink: URL?) -> Bool {
        print("Deferred deep link callback called!")
        print("Deferred deep link URL: \(deeplink?.absoluteString ?? "")")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Show ATT dialog.
        Adjust.requestAppTrackingAuthorization { status in
            switch status {
            case 0:
                // ATTrackingManagerAuthorizationStatusNotDetermined case
                break
            case 1:
                // ATTrackingManagerAuthorizationStatusRestricted case
                break
            case 2:
                // ATTrackingManagerAuthorizationStatusDenied case
                break
            case 3:
                // ATTrackingManagerAuthorizationStatusAuthorized case
                break
            default:
                break
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
}


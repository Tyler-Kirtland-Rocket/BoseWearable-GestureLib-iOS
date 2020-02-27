//
//  AppDelegate.swift
//  GestureExample
//
//  Created by Paul Calnan on 11/19/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import BoseWearable
import BoseGesture
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Enable BoseWearable logging.
        BoseWearable.enableCommonLogging()

        // Configure the BoseWearable SDK
        BoseWearable.configure()

        // Configure the BoseGesture library
        BoseGesture.configure()

        return true
    }
}

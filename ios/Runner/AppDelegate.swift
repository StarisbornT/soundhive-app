// import Flutter
// import UIKit

// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

import Flutter
import UIKit
import BackgroundTasks
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Set UNUserNotificationCenter delegate
    UNUserNotificationCenter.current().delegate = self

    // Register for remote notifications
    application.registerForRemoteNotifications()

    // Register background tasks
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.soundhive.backgroundTask1", using: nil) { task in
      self.handleBackgroundTask(task, identifier: "com.soundhive.backgroundTask1")
    }
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.soundhive.backgroundTask2", using: nil) { task in
      self.handleBackgroundTask(task, identifier: "com.soundhive.backgroundTask2")
    }

    // Handle notification launch (terminated state)
    if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      handleNotificationLaunch(userInfo: userInfo)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notification when app is launched or tapped
  private func handleNotificationLaunch(userInfo: [AnyHashable: Any]) {
    // Convert [AnyHashable: Any] to [String: Any]
    var notificationData: [String: Any] = [:]
    for (key, value) in userInfo {
      if let stringKey = key as? String {
        notificationData[stringKey] = value
      }
    }

    // Handle aps.alert for notification title and body
    if let aps = notificationData["aps"] as? [String: Any], let alert = aps["alert"] as? [String: Any] {
      notificationData["title"] = alert["title"]
      notificationData["body"] = alert["body"]
    }

    // Serialize to JSON and pass to Flutter
    if let jsonData = try? JSONSerialization.data(withJSONObject: notificationData, options: []),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      if let flutterViewController = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(name: "com.soundhive/notifications", binaryMessenger: flutterViewController.binaryMessenger)
        channel.invokeMethod("onNotificationTap", arguments: jsonString)
      }
    }
  }

  // Handle background tasks
  private func handleBackgroundTask(_ task: BGTask, identifier: String) {
    scheduleBackgroundTask(identifier: identifier)
    print("Running background task: \(identifier)")
    task.setTaskCompleted(success: true)
  }

  // Schedule a background task
  private func scheduleBackgroundTask(identifier: String) {
    let request = BGProcessingTaskRequest(identifier: identifier)
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    do {
      try BGTaskScheduler.shared.submit(request)
      print("Scheduled background task: \(identifier)")
    } catch {
      print("Failed to schedule background task \(identifier): \(error)")
    }
  }

  // Handle notification taps (foreground/background)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    handleNotificationLaunch(userInfo: userInfo)
    completionHandler()
  }

  // Handle remote notification registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }

  // Handle foreground notifications
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
}

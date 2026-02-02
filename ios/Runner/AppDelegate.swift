import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var appBlockingChannel: Any?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 16.0, *) {
      if let controller = window?.rootViewController as? FlutterViewController {
        appBlockingChannel = AppBlockingChannel(messenger: controller.binaryMessenger)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

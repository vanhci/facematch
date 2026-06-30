import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    BackgroundTaskPlugin.register(with: self.registrar(forPlugin: "BackgroundTaskPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

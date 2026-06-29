import Foundation
import Flutter

@objc public class BackgroundTaskPlugin: NSObject, FlutterPlugin {
    var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.vanhci.facematch/background", binaryMessenger: registrar.messenger())
        let instance = BackgroundTaskPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startTask":
            startBackgroundTask()
            result(true)
        case "endTask":
            endBackgroundTask()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startBackgroundTask() {
        endBackgroundTask()
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "facematchTransfer") {
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
}

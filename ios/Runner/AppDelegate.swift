import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let permissionsChannel = FlutterMethodChannel(name: "com.example.vpn/permissions",
                                                  binaryMessenger: controller.binaryMessenger)
    
    permissionsChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "requestPermission" {
        self.requestPermission(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestPermission(result: @escaping FlutterResult) {
    // Add your permission request logic here.
    // Example: Always return true for testing purposes
    result(true)
  }
}

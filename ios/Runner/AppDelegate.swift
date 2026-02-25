import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialiser Firebase avant tout
    FirebaseApp.configure()
    
    // Configurer le délégué Firebase Messaging (obligatoire si FirebaseAppDelegateProxyEnabled = false)
    Messaging.messaging().delegate = self
    
    // Demander les permissions de notification au démarrage
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Permissions de notification accordées")
          } else {
            print("❌ Permissions de notification refusées")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // Enregistrer l'application pour les notifications distantes (APNS)
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Gérer l'enregistrement pour les notifications distantes
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ Token APNS reçu: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    
    // Comme FirebaseAppDelegateProxyEnabled = false, on doit transmettre manuellement le token APNS à Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Échec de l'enregistrement pour les notifications distantes: \(error)")
  }
  
  // Callback Firebase Messaging pour recevoir le token FCM
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else {
      print("⚠️ Token FCM non disponible (nil)")
      return
    }
    
    print("✅ Token FCM reçu: \(fcmToken)")
  }
}

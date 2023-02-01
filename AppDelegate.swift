import UIKit

import IplabsSdk
import Amplitude


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Init MobileEditors SDK
        var applicationSupportDirectory =  FileManager.default.urls(for: .applicationSupportDirectory, in: .allDomainsMask).first
        applicationSupportDirectory = applicationSupportDirectory?.appendingPathComponent("myorganization/projects")

        // can throw the alreadInitializedError
        _ = try! IplabsMobileSdk(
            operatorId: 97000040,
            locale: "en_GB",
            baseUrl: "https://shared1-staging.iplabs.io/97000040/",
            externalCartServiceBaseUrl: "https://external-cart.staging.eu-central-1.iplabs.io",
            localProjectsLocation: applicationSupportDirectory,
            translationsSource: Bundle.main.url(forResource: "translations", withExtension: "json"),
            userTrackingPermission: UserService.instance.trackingPermission
        )
        
        // SDK keeps the session between app restarts, so we log out explicitly unless we have implemented session storage within the demo app
        IplabsMobileSdk.shared.logout()
        
        if let amplitudeApiKey = ConfigService.shared.getInfoPlistString(for: "AMPLITUDE_API_KEY") {
            Amplitude.instance().initializeApiKey(amplitudeApiKey)
            Amplitude.instance().trackingSessionEvents = true
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

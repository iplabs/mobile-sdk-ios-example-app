import Foundation
import CryptoKit

import IplabsSdk

public class UserService {
    static let instance = UserService()
    static let serializedUserKey = "SerializedUser"
    private let trackingPermissionKey = "UserTrackingPermission"

    private(set) var sessionId: String?
    private var _trackingPermission = UserTrackingPermission.allow
    
    public var trackingPermission: UserTrackingPermission {
        set {
            IplabsMobileSdk.shared.userTrackingPermission = newValue
            if let serializedPermission = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(serializedPermission, forKey: trackingPermissionKey)
            }
        }
    
        get {
            return _trackingPermission
        }
    }
    
    private init()  {
        // load persisted userTrackingPermission
        if let persistedTrackingPermissionData = UserDefaults.standard.data(forKey: trackingPermissionKey),
           let persistedTrackingPermission = try? JSONDecoder().decode(UserTrackingPermission.self, from: persistedTrackingPermissionData) {
                _trackingPermission = persistedTrackingPermission
        }
    }


    func loginUser(email: String, completionHandler: @escaping(String?) -> Void) {
        // here would be a request to your login backend to provide a valid Wipe SSO session id
    }

    func invalidateSessionId() {
        self.sessionId = nil
        IplabsMobileSdk.shared.logout()
    }
}

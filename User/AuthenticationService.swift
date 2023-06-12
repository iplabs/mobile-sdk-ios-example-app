import UIKit

import IplabsSdk

class AuthenticationService {
    static let shared = AuthenticationService()
    private let userManagementEnabled = ConfigService.shared.getInfoPlistURL(for: "ADD_USER_INFO_URL") != nil

    private func currentViewController() -> UIViewController? {
        let window = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        return window?.rootViewController
    }

    private func dismisLoadingViewController() {
        if (self.currentViewController()?.presentedViewController is UIAlertController) {
            self.currentViewController()?.dismiss(animated: true)
        }
    }

    private func loadingViewController() -> UIAlertController {
        let vc = UIAlertController(title: nil, message: "Logging you in…", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();

        vc.view.addSubview(loadingIndicator)

        return vc
    }

    private func showLoginModal(resultCallback: @escaping (String?) -> Void) {
        let message = userManagementEnabled ? "Demo login: You can use your e-mail address and any password." : "Here you need to provide a login screen. This dialog is for demo purposes only and is not functional in this example app."
        let alertController = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        
        alertController.view.accessibilityIdentifier = "login-modal"

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action  in
            resultCallback(.none)
        }

        let loginAction = UIAlertAction(title: "Login", style: .default) { action in
            /*
             Do actual login an pass correct sessionId
            */

            self.currentViewController()?.present(self.loadingViewController(), animated: true, completion: nil)

            let email = alertController.textFields?[0].text ?? ""
            UserService.instance.loginUser(email: email) { sessionId in
                resultCallback(sessionId)
                DispatchQueue.main.async {
                    self.dismisLoadingViewController()
                }
            }
        }
        
        loginAction.accessibilityIdentifier = "login-action-button"
        loginAction.isEnabled = userManagementEnabled

        alertController.addTextField() { textField in
            textField.placeholder = "E-Mail"
            textField.accessibilityIdentifier = "login-email-textfield"
        }

        alertController.addTextField() { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        alertController.addAction(cancelAction)
        alertController.addAction(loginAction)
        
        self.currentViewController()?.present(alertController, animated: true)
    }

    private func showErrorModal() {
        let alertController = UIAlertController(title: "Error", message: "Sorry, something went wrong. Please try again.", preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default)
        alertController.addAction(closeAction)

        self.currentViewController()?.present(alertController, animated: true)
    }
}

extension AuthenticationService: AuthenticationDelegate {
    public func authenticationFailed(reason: AuthenticationError) {
        self.showErrorModal()
        print(reason)
    }

    public func requestSessionId(authenticateCallback: @escaping (String) -> Void,
                                cancelAuthenticationCallback: @escaping () -> Void) {
        if let sessionId = UserService.instance.sessionId {
            authenticateCallback(sessionId)
        } else {
            self.showLoginModal() { sessionId in
                if let sessionId = sessionId {
                    authenticateCallback(sessionId)
                } else {
                    cancelAuthenticationCallback()
                }
            }
        }
    }
    
    public func logout() {
        UserService.instance.invalidateSessionId()
    }
}

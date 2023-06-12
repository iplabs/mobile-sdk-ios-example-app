import Foundation
import UIKit

import IplabsSdk
import Amplitude

class MainViewController: UIViewController {
    @IBOutlet var mainView: UIView!
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    lazy var editorViewController: EditorViewController = {
        let productConfiguration = ProductConfiguration(id: self.productId, options: selectedOptions)
        let editorConfiguration = EditorConfiguration(allowMultipleElementsForWallDecor: false)
        let branding = Branding(primaryColor: "#000")

        let vc: EditorViewController

        if let cartProject = cartProject {
            vc = IplabsMobileSdk.shared.initializeEditor(cartProject: cartProject, editorConfiguration: editorConfiguration, branding: branding)
        } else if let projectToLoad = projectToLoad {
            vc = IplabsMobileSdk.shared.initializeEditor(project: projectToLoad, sessionId: UserService.instance.sessionId, editorConfiguration: editorConfiguration, branding: branding)
        } else {
            vc = IplabsMobileSdk.shared.initializeEditor(productConfiguration: productConfiguration, editorConfiguration: editorConfiguration, branding: branding)
        }

        vc.editorViewDelegate = self
        vc.authenticationDelegate = AuthenticationService.shared

        return vc
    }()

    public var productId: Int = 0
    public var selectedOptions: [String:String] = [:]
    public var projectToLoad: Project? {
        didSet {
            if let projectToLoad = projectToLoad {
                productId = projectToLoad.productId
                selectedOptions = projectToLoad.appliedProductOptions
            }
        }
    }
    public var cartProject: CartProject?
    
    private func setupViews() {
        let editorView = editorViewController.view!
        addChild(editorViewController)
        mainView.addSubview(editorView)
        editorViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            editorView.topAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            editorView.leftAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            editorView.bottomAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            editorView.rightAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor)
        ])
        
        let backButton = UIButton(type: .close)
        backButton.addTarget(self, action: #selector(backButtonTapped(_:)), for:.touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        self.navigationItem.rightBarButtonItem = nil
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        editorViewController.requestTermination() { editorState in
           if editorState == .ready {
                self.navigationController?.popViewController(animated: true)
                self.editorViewController.editorViewDelegate = nil
            }
        }
    }

    private func showErrorModal(completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Error", message: "Sorry, something went wrong. Please try again.", preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default ) {_ in
            completionHandler()
        }
        alertController.addAction(closeAction)

        self.present(alertController, animated: true)
    }
}

extension MainViewController: EditorViewDelegate {
    func receiveAnalyticsEvent(event: AnalyticsEvent) {
        print(event)
        Amplitude.instance().logEvent(event.name, withEventProperties: event.properties)
    }
    
    func transferCartProject(cartProject: CartProject) {
        let cartItem = CartItem(cartProject: cartProject)
        CartService.instance.addItem(cartItem: cartItem)
        
        self.tabBarController?.selectedIndex = 1
        self.navigationController?.popToRootViewController(animated: false)
    }

    func handleLoadProjectTapped() {
       

        self.editorViewController.requestTermination() { state in
            if (state == .ready) {
                // pop to any previous StoredProjectsTableViewController if it exists
                if let previousProjectsTableViewController = self.navigationController?.viewControllers.first(where: { $0 is StoredProjectsTableViewController }) {
                    
                    self.navigationController?.popToViewController(previousProjectsTableViewController, animated: true)
                } else {
                    // create new StoredProjectsTableViewController
                    guard let projectsTableViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "StoredProjectsView") as? StoredProjectsTableViewController else {
                        return
                    }
                    
                    projectsTableViewController.authenticationDelegate = AuthenticationService.shared
                    self.navigationController?.popToRootViewController(animated: true)
                    self.navigationController?.pushViewController(projectsTableViewController, animated: true)
                }
            }
        }
    }

    func editCartProjectFailed(reason: CartProjectEditingError) {
        switch reason {
        case .authenticationMissingError:
            self.navigationController?.popViewController(animated: true)
        default:
            self.showErrorModal() {
                self.navigationController?.popViewController(animated: true)
            }
        }

        print(reason)
    }
}

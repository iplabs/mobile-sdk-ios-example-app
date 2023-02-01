import Foundation
import UIKit

import IplabsSdk

class AccountTableViewController: UITableViewController {
    @IBOutlet var accountHeaderView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.tableHeaderView = isLoggedIn() ? self.accountHeaderView : nil
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountRow", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel!.text = "Stored Projects"
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil

            break
        case 1:
            if isLoggedIn() {
                cell.textLabel!.text = "Logout"
            } else {
                cell.textLabel!.text = "Login / Registration"
            }
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil

            break
        case 2:
            cell.textLabel!.text = "Tracking consent"

            let consentSwitch = UISwitch()
            consentSwitch.setOn(UserService.instance.trackingPermission == .allow, animated: true)
            consentSwitch.tag = indexPath.row
            consentSwitch.addTarget(self, action: #selector(self.consentSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = consentSwitch
            
            break
        default:
            break
        }
        

        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
            switch indexPath.row {
            case 0:
                self.performSegue(withIdentifier: "showStoredProjects", sender: self)
                
                break
            case 1:
                if isLoggedIn() {
                    let alertController = UIAlertController(title: "Logout", message: "Do you really want to log out?", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Close", style: .default)
                    let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { action in
                        AuthenticationService.shared.logout()
                        self.tableView.tableHeaderView = nil
                        self.tableView.reloadData()
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(logoutAction)

                    self.present(alertController, animated: true)
                } else {
                    AuthenticationService.shared.requestSessionId(authenticateCallback: { sessionId in
                        Task(priority: .medium) {
                            self.tableView.tableHeaderView = self.accountHeaderView
                            self.tableView.reloadData()
                        }
                    }, cancelAuthenticationCallback: {
                        Task(priority: .medium) {
                            self.tableView.tableHeaderView = nil
                            self.tableView.reloadData()
                        }
                    })
                }

                break
            default:
                break
            }
    }
    
    // MARK: - Other functions
    
    private func isLoggedIn() -> Bool {
        return UserService.instance.sessionId != nil
    }
    
    @objc private func consentSwitchChanged(_ sender : UISwitch!){
        UserService.instance.trackingPermission = sender.isOn ? .allow : .forbid
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        if segue.identifier == "showStoredProjects" {
            let vc = segue.destination as! StoredProjectsTableViewController
            vc.authenticationDelegate = AuthenticationService.shared
        }
    }
}

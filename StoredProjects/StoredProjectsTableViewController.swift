import UIKit

import IplabsSdk

class StoredProjectsTableViewController: UITableViewController {
    @IBOutlet weak var cloudLoginHeaderView: UIView!
    @IBOutlet weak var emptyListBackgroundView: UIView!

    private var projects: [Project]?

    private func loadStoredProjects(sessionId: String?) async {
        do {
            let localProjects = try await IplabsMobileSdk.shared.retrieveLocalProjects().get()
            var mergedProjects = localProjects

            // load cloud projects
            if let sessionId = sessionId {
                let cloudProjects = try await IplabsMobileSdk.shared.retrieveCloudProjects(sessionId: sessionId).get()
                mergedProjects += cloudProjects
            }

            self.projects = mergedProjects.sorted(by: {$0.lastModifiedDate > $1.lastModifiedDate})
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch(let error) {
            showErrorModal(message: error.localizedDescription)
        }
    }

    private func showErrorModal(message: String) {
        showModal(message: "Sorry, something went wrong. (\(message))", title: "Error")
    }
    
    private func showModal(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default)
        alertController.addAction(closeAction)

        self.present(alertController, animated: true)
    }

    /// Delegate to handle authentication events
    public var authenticationDelegate: AuthenticationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // edit button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let _ = UserService.instance.sessionId {
            requestSessionId()
        } else {
            self.tableView.tableHeaderView = self.cloudLoginHeaderView

            Task(priority: .medium) {
                await self.loadStoredProjects(sessionId: nil)
            }
        }
    }

    private func requestSessionId() {
        self.authenticationDelegate?.requestSessionId(authenticateCallback: { sessionId in
            Task(priority: .medium) {
                self.tableView.tableHeaderView = nil

                await self.loadStoredProjects(sessionId: sessionId)
            }
        }, cancelAuthenticationCallback: {
            self.tableView.tableHeaderView = self.cloudLoginHeaderView
        })
    }

    @IBAction func editButtonTapped(_ sender: Any) {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: tableView.isEditing ? .edit : .done, target: self, action: #selector(editButtonTapped))
        tableView.setEditing(!tableView.isEditing, animated: true)
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        requestSessionId()
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        let cell = sender as! UITableViewCell
        let indexPath = self.tableView.indexPath(for: cell)!

        guard let project = self.projects?[indexPath.row],
              let mainViewController = segue.destination as? MainViewController else {
            return
        }

        mainViewController.projectToLoad = project
    }

    private func showRenameModal(project: Project, resultCallback: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Rename Project", message: "Rename the project. Empty text is not allowed.", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action  in
            resultCallback(.none)
        }

        let renameAction = UIAlertAction(title: "Rename", style: .default) { action in
            let updatedProjectName = alertController.textFields?[0].text ?? ""
            resultCallback(updatedProjectName)
        }
        
        renameAction.accessibilityIdentifier = "rename-project-action-button"

        alertController.addTextField() { textField in
            textField.placeholder = "Project name"
            textField.text = project.title
            textField.accessibilityIdentifier = "rename-project-text-field"
            textField.clearButtonMode = .always
        }

        alertController.addAction(cancelAction)
        alertController.addAction(renameAction)

        self.present(alertController, animated: true)
    }

    private func renameProject(project: Project, indexPath: IndexPath, projectName: String) async {
        switch project.location {
        case .local:
            switch await IplabsMobileSdk.shared.renameLocalProject(project: project, newTitle: projectName) {
            case .success(_):
                await self.loadStoredProjects(sessionId: UserService.instance.sessionId)
            case .failure(_):
                showErrorAlertRenamingProject(project: project)
            }
        case .cloud:
            if let sessionId = UserService.instance.sessionId {
                switch await IplabsMobileSdk.shared.renameCloudProject(project: project, newTitle: projectName, sessionId: sessionId) {
                case .success(_):
                    await self.loadStoredProjects(sessionId: UserService.instance.sessionId)
                case .failure(_):
                    showErrorAlertRenamingProject(project: project)
                }
            }
        default:
            print("Project renaming failed. Failed identifying project type.")
        }
    }

    private func deleteProject(project: Project, indexPath: IndexPath) async {
        let shouldDelete = await self.showDeleteModal(project: project)
        if shouldDelete {
            switch project.location {
            case .local:
                switch await IplabsMobileSdk.shared.deleteLocalProject(project: project) {
                case .success():
                    self.projects?.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)

                case .failure(_):
                   showErrorAlertDeletingProject(project: project)
                }
            case .cloud:
                if let sessionId = UserService.instance.sessionId {
                    switch await IplabsMobileSdk.shared.deleteCloudProject(project: project, sessionId: sessionId) {
                    case .success():
                        self.projects?.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)

                    case .failure(_):
                       showErrorAlertDeletingProject(project: project)
                    }
                }
            default:
                print("Project deletion failed. Failed identifying project type.")
            }
        }
    }

    private func showErrorAlertDeletingProject(project: Project) {
        let alertController = UIAlertController(title: "Error", message: "Deleting project \"\(project.title)\" was not successful.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    private func showErrorAlertRenamingProject(project: Project) {
        let alertController = UIAlertController(title: "Error", message: "Renaming project \"\(project.title)\" was not successful.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    private func showDeleteModal(project: Project) async -> Bool {
        let alertController = UIAlertController(title: "Delete Project", message: "Do you really want to delete project \"\(project.title)\"?", preferredStyle: .alert)

        return await withCheckedContinuation { continuation in
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action  in
                continuation.resume(returning: false)
            }

            let deleteAction = UIAlertAction(title: "Delete", style: .default) { action in
                continuation.resume(returning: true)
            }
            deleteAction.accessibilityIdentifier = "delete-project-action-button"
            alertController.addAction(cancelAction)
            alertController.addAction(deleteAction)

            self.present(alertController, animated: true)
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let numOfProjects = self.projects?.count ?? 0
        self.tableView.backgroundView = numOfProjects == 0 ? self.emptyListBackgroundView : nil

        return numOfProjects
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ProjectTableViewCell

        guard let project = self.projects?[indexPath.row] else {
            return cell
        }

        cell.setCellData(project: project)
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let project = self.projects?[indexPath.row] else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            (action, sourceView, completionHandler) in
            Task {
                await self.deleteProject(project: project, indexPath: indexPath)
            }

            completionHandler(true)
        }
        deleteAction.accessibilityLabel = "delete-project-contextual-action"

        let renameAction = UIContextualAction(style: .normal, title: "Rename") {
            (action, sourceView, completionHandler) in

            self.showRenameModal(project: project) { updatedProjectName in
                if let updatedProjectName = updatedProjectName, !updatedProjectName.isEmpty {
                    Task {
                        await self.renameProject(project: project, indexPath: indexPath, projectName: updatedProjectName)
                    }
                } else {
                    self.showModal(message: "Please add a title that is not empty")
                }
            }

            completionHandler(true)
        }
        renameAction.backgroundColor = UIColor(red: 28.0/255.0, green: 165.0/255.0, blue: 253.0/255.0, alpha: 1.0)
        
        renameAction.accessibilityLabel = "rename-project-contextual-action"

        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        swipeConfiguration.performsFirstActionWithFullSwipe = false

        return swipeConfiguration
    }
}

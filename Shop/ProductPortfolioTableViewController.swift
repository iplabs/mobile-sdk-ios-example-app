import UIKit

import IplabsSdk

class ProductPortfolioTableViewController: UITableViewController {
    private var products: [Product]?
    
    // hide any products which should not be presented to the user 
    private var hiddenProductIds = [50035648, 50035650, 60002077]

    private func loadPortfolioProducts() async {
        let result = await IplabsMobileSdk.shared.retrieveProductPortfolio()
        switch result {
        case .success(let portfolio):
            self.products = portfolio.products.filter({ !hiddenProductIds.contains($0.id) })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        case .failure(let error):
            print(error)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task(priority: .medium) {
            await self.loadPortfolioProducts()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.products?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ProductPortfolioTableViewCell

        guard let product = self.products?[indexPath.row] else {
            return cell
        }

        cell.setCellData(product: product)
        return cell
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        if segue.identifier == "showStoredProjects" {
            let vc = segue.destination as! StoredProjectsTableViewController
            vc.authenticationDelegate = AuthenticationService.shared
        } else {
            guard let cell = sender as? UITableViewCell,
                  let indexPath = self.tableView.indexPath(for: cell),
                  let product = self.products?[indexPath.row],
                  let productViewController = segue.destination as? ProductViewController
            else {
                return
            }

            productViewController.product = product
        }
    }
}

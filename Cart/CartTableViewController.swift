import UIKit

import IplabsSdk

class CartTableViewController: UITableViewController {
    private var curSelectedCartItem: CartItem?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.rightBarButtonItem?.isEnabled = !CartService.instance.isEmpty
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "submit-order-button"
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CartService.instance.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemTableCell", for: indexPath) as! CartTableViewCell

        let cartItem = CartService.instance.items[indexPath.row]

        let cartProject = cartItem.cartProject

        let previewImage = cartProject.previewImage ?? UIImage(systemName: "cart")!

        let title = cartProject.title ??
                    cartProject.productName

        let subtitle = cartProject.options.reduce("") { partialResult, option in
            return partialResult + option.0 + ": " + option.1 + "\n"
        }

        let price = String(format: "%.2f", cartProject.price) + " €"

        print("cartItem.quantity: \(cartItem.quantity)")
        cell.setCellData(image: previewImage, title: title, subtitle: subtitle, price: price, quantity: cartItem.quantity)

        cell.quantityTapped = {
            self.curSelectedCartItem = cartItem
            self.performSegue(withIdentifier: "selectQuantity", sender: self)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            (action, sourceView, completionHandler) in
            CartService.instance.removeItem(atIndex: indexPath.row)

            self.tableView.deleteRows(at: [indexPath], with: .fade)

            completionHandler(true)
        }

        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction])
        swipeConfiguration.performsFirstActionWithFullSwipe = true

        return swipeConfiguration
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        if segue.identifier == "selectQuantity" {
            let destVC = segue.destination as! UINavigationController
            let topVC = destVC.topViewController as! CartQuantityPickerViewController
            topVC.curQuantity = curSelectedCartItem?.quantity ?? 1
            topVC.delegate = self
        } else {
            guard let cell = sender as? UITableViewCell,
                  let indexPath = self.tableView.indexPath(for: cell),
                  let mainViewController = segue.destination as? MainViewController else {
                    return
            }
            let cartItem = CartService.instance.items[indexPath.row]
            let cartProject = cartItem.cartProject
            mainViewController.cartProject = cartProject
        }
    }
}

extension CartTableViewController: CartQuantityDelegate {
    func quantityChangedTo(quantity: Int) {
        if let curSelectedCartItem = curSelectedCartItem {
            var updatedCartItem = curSelectedCartItem
            updatedCartItem.quantity = quantity
            CartService.instance.quantityUpdatedFor(cartItem: updatedCartItem)
            tableView.reloadData()
        }
    }
}

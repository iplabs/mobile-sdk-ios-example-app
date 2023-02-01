import UIKit

import IplabsSdk

class OrderConfirmationViewController: UIViewController {
    @IBOutlet weak var orderStatusIcon: UIImageView!
    @IBOutlet weak var orderStatusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let orderItems = CartService.instance.items.map({ item in
            return OrderItem(cartProjectRevisionId: item.cartProject.revisionId, quantity: item.quantity, netPriceOverride: 23)
        })

        let postalAddress = Address(
            countryIsoCode: "DE",
            salutation: "Mr.",
            firstName: "John",
            lastName: "Doe",
            street: "Main Street 123",
            zipCode: "1234",
            city: "Largetown",
            phoneNumber: "0049123456789"
        )

        let userInfo = UserInfo(
            eMailAddress: "john.doe@example.com",
            billingAddress: postalAddress,
            shippingAddress: postalAddress,
            firstName: "John",
            lastName: "Doe"
        )

        // replace this with the actual order id used in your systems
        let orderId = UUID.init().uuidString
        
        guard let submitOrderSecret = ConfigService.shared.getInfoPlistString(for: "SUBMIT_ORDER_SECRET")  else {
            self.orderStatusIcon.image = UIImage(systemName: "questionmark.circle.fill")!
            self.orderStatusLabel.text = "You need a secret to submit an order. Please contact ip.labs for onboarding."
            
            return
        }
        
        IplabsMobileSdk.shared.submitOrder(id: orderId, items: orderItems, secret: submitOrderSecret, userInfo: userInfo) { result in
            switch result {
            case .success(let orderId):
                CartService.instance.clear()

                DispatchQueue.main.async {
                    self.orderStatusIcon.image = UIImage(systemName: "checkmark.circle.fill")!
                    self.orderStatusLabel.text = "Your order with id " + orderId + " was successful"
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.orderStatusIcon.image = UIImage(systemName: "xmark.circle.fill")!
                    self.orderStatusLabel.text = "Sorry, something went wrong submitting your order!"
                }
            }
        }
    }
}

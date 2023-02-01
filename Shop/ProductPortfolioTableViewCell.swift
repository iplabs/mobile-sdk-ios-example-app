import UIKit

import IplabsSdk

class ProductPortfolioTableViewCell: UITableViewCell {
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setCellData(product: Product) {
        self.productNameLabel.text = product.name
        self.priceLabel.text = "from \(product.bestPrice) €"
        self.accessibilityIdentifier = "product-\(product.id)"
    }
}

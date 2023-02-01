import UIKit

class CartTableViewCell: UITableViewCell {
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var quantityButton: UIButton!

    var quantityTapped: (() -> ())?

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setCellData(image: UIImage, title: String, subtitle: String, price: String, quantity: Int) {
        self.previewImage.image = image
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
        self.priceLabel.text = price
        self.quantityButton.setTitle("\(quantity)", for: .normal)
    }

    @IBAction private func quantityTapped(_ sender: UIButton) {
        quantityTapped?()
    }
}

import UIKit

import IplabsSdk

class ProductViewController: UIViewController {
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productDescriptionLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var startEditorButton: UIButton!

    public var product: Product?
    private var selectedOptions: [String:String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        productNameLabel.text = product?.name
        productDescriptionLabel.text = product?.description

        product?.options.forEach({ option in

            self.selectedOptions[option.id] = option.defaultValue

            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .firstBaseline
            row.distribution = .equalSpacing

            let optionLabel = UILabel()
            optionLabel.text = option.name
            row.addArrangedSubview(optionLabel)

            let optionCount = option.values.count

            switch optionCount {
            case ..<2:
                return
            default:
                let optionButton = UIButton(primaryAction: nil)
                let menuItems = option.values.map { value -> UIAction in
                    let state: UIAction.State = value.id == option.defaultValue ? .on : .off
                    return UIAction(title: value.name, identifier: UIAction.Identifier( value.id), state: state) { action in
                        self.selectedOptions[option.id] = value.id
                        print (value.id)
                    }
                }
                let menu = UIMenu(title: option.name, image: nil, identifier: UIMenu.Identifier(option.id), options: [], children: menuItems)
                optionButton.menu = menu

                optionButton.setTitleColor(.systemBlue, for: .normal)
                optionButton.showsMenuAsPrimaryAction = true
                if #available(iOS 15.0, *) {
                    optionButton.changesSelectionAsPrimaryAction = true
                } else {
                    let defaultValue = option.values.first(where: {$0.id == option.defaultValue})
                    optionButton.setTitle(defaultValue?.name, for: .normal)
                }

                row.addArrangedSubview(optionButton)
            }
            self.stackView.addArrangedSubview(row)
        })
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        guard let product = self.product,
              let mainViewController = segue.destination as? MainViewController
        else {
            return
        }

        mainViewController.productId = product.id
        mainViewController.selectedOptions = self.selectedOptions
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

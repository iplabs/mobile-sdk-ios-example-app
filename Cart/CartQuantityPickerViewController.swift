import UIKit

protocol CartQuantityDelegate {
  func quantityChangedTo(quantity: Int)
}

class CartQuantityPickerViewController: UIViewController {
    @IBOutlet weak var pickerView: UIPickerView!
    var delegate: CartQuantityDelegate?

    var curQuantity = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Quantity"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        self.pickerView.selectRow(curQuantity-1, inComponent: 0, animated: false)
    }

    @IBAction func cancelTapped() {
        dismiss(animated: true)
    }

    @IBAction func saveTapped() {
        delegate?.quantityChangedTo(quantity: curQuantity)
        dismiss(animated: true)
    }
}

extension CartQuantityPickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        curQuantity = row + 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 50
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
}

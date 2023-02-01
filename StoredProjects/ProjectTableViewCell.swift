import UIKit

import IplabsSdk

class ProjectTableViewCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var optionsLabel: UILabel!
    @IBOutlet weak var lastModifiedLabel: UILabel!
    @IBOutlet weak var locationIndicatorImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setCellData(project: Project) {
        self.previewImageView.image = project.previewImage
        self.locationIndicatorImageView.image = project.location == .cloud ? UIImage(systemName: "icloud.and.arrow.down") : UIImage(systemName: "iphone")
        self.nameLabel.text = project.title
        
        let optionsTitle = project.appliedProductOptions.reduce("") { partialResult, option in
            return partialResult + option.0 + ": " + option.1 + "\n"
        }
        self.optionsLabel.text = optionsTitle
        let lastModifiedDate = project.lastModifiedDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.lastModifiedLabel.text = dateFormatter.string(from: lastModifiedDate)
    }
}

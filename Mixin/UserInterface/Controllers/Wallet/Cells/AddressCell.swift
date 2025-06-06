import UIKit
import MixinServices

final class AddressCell: ModernSelectedBackgroundCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    func render(address: Address) {
        nameLabel.text = address.label
        addressLabel.text = address.fullRepresentation
        dateLabel.text = address.updatedAt.toUTCDate().timeAgo()
    }
    
}

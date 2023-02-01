import Foundation

import IplabsSdk

struct CartItem: Codable {
    let cartProject: CartProject
    var quantity: Int = 1
}

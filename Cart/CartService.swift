import Foundation

import IplabsSdk

public class CartService {
    static let instance = CartService()
    private let userDefaultsKey = "CartItems"
    var items: [CartItem] = []

    var isEmpty: Bool {
        get { return self.items.count == 0 }
    }

    init() {
        if let persistedItemsData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let persistedItems = try? JSONDecoder().decode([CartItem].self, from: persistedItemsData) {
                self.items = persistedItems
            }
        }
    }

    func clear() {
        self.items = []
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    func addItem(cartItem: CartItem) {
        let existingItemIndex = self.items.firstIndex() { $0.cartProject.id == cartItem.cartProject.id }
        if let index = existingItemIndex {
            self.items[index] = cartItem
        } else {
            self.items.append(cartItem)
        }

        self.persistCartItems()
    }

    func removeItem(atIndex index: Int) {
        self.items.remove(at: index)
        self.persistCartItems()
    }

    func quantityUpdatedFor(cartItem: CartItem) {
        if let cartItemIndex = items.firstIndex(where: { $0.cartProject.id == cartItem.cartProject.id && $0.cartProject.revisionId == cartItem.cartProject.revisionId}) {
            self.items[cartItemIndex] = cartItem
        }
        self.persistCartItems()
    }

    private func persistCartItems() {
        if let encodedItems = try? JSONEncoder().encode(self.items) {
            UserDefaults.standard.set(encodedItems, forKey: userDefaultsKey)
        }
    }
}

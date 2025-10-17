import Foundation

extension VocabItem {
    func copyWithNewID() -> VocabItem {
        var newItem = self
        newItem.id = UUID()
        return newItem
    }
}

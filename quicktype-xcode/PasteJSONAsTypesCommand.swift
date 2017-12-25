import Foundation

class PasteJSONAsTypesCommand: PasteJSONAsCodeCommand {
    override var renderTypesOnly: Bool {
        return true
    }
}

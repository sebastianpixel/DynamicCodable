protocol OptionalProtocol {
    var isNil: Bool { get }
}
extension Optional: OptionalProtocol {
    var isNil: Bool {
        if case .none = self {
            return true
        }
        return false
    }
}

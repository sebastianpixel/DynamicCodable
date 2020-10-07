@propertyWrapper
public final class DynamicCodable<Value>: Codable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    required public convenience init(from decoder: Decoder) throws {
        try self.init(wrappedValue: DynamicDecodable<Value>(from: decoder).wrappedValue)
    }

    public func encode(to encoder: Encoder) throws {
        try DynamicEncodable(wrappedValue: self.wrappedValue).encode(to: encoder)
    }
}

extension DynamicCodable: Equatable {
    public static func == (lhs: DynamicCodable<Value>, rhs: DynamicCodable<Value>) -> Bool {
        DynamicEncodable(wrappedValue: lhs) == DynamicEncodable(wrappedValue: rhs)
    }
}

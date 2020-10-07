import Foundation

@propertyWrapper
public struct DynamicEncodable<Value>: Encodable {

    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        if let encodable = wrappedValue as? Encodable {
            var container = encoder.singleValueContainer()
            try encodable.encode(to: &container)
        } else if let encodableArray = wrappedValue as? [Encodable] {
            var container = encoder.unkeyedContainer()
            try encodableArray.encode(to: &container)
        } else if let encodableDictionary = wrappedValue as? [AnyHashable: Encodable] {
            var container = encoder.container(keyedBy: CustomCodingKey.self)
            for (key, value) in encodableDictionary {
                let codingKey = CustomCodingKey("\(key.base)")
                try value.encode(for: codingKey, to: &container)
            }
        } else if let optional = wrappedValue as? OptionalProtocol, optional.isNil {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        } else {
            throw EncodingError.invalidValue(
                Value.self,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription: "Type not conforming to Encodable."
                )
            )
        }
    }
}

private extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }

    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }

    func encode<K: CodingKey>(for key: K, to container: inout KeyedEncodingContainer<K>) throws {
        try container.encode(self, forKey: key)
    }
}

private extension Array where Element == Encodable {
    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try forEach { try $0.encode(to: &container) }
    }
}

extension DynamicEncodable: Equatable {
    public static func == (lhs: DynamicEncodable<Value>, rhs: DynamicEncodable<Value>) -> Bool {
        let jsonEncoder = JSONEncoder()
        return (try? jsonEncoder.encode(lhs) == jsonEncoder.encode(rhs)) ?? false
    }
}

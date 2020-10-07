struct CustomCodingKey: CodingKey {
    var stringValue: String

    init(_ string: String) {
        stringValue = string
        intValue = Int(string)
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = Int(stringValue)
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

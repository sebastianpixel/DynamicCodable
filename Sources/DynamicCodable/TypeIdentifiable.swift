import Foundation

public protocol TypeIdentifiable {
    /// Instance type property necessary for retrieving the type to
    /// decode and encoding it for later re-decoding.
    ///
    /// **Important**: default implementations of protocol properties
    /// are computed properties and would therefore not be encoded.
    var type: String { get }
}

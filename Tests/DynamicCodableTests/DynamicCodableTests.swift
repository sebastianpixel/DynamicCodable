import XCTest
@testable import DynamicCodable

final class DynamicCodableTests: XCTestCase {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let homeScreen = HomeScreenRoute()
    private var detailScreen: DetailScreenRoute {
        .init(id: .init())
    }

    override class func setUp() {
        super.setUp()

        DynamicDecodableRegistry.register(DetailScreenRoute.self, typeIdentifier: DetailScreenRoute.type)
        DynamicDecodableRegistry.register(HomeScreenRoute.self, typeIdentifier: HomeScreenRoute.type)
    }

    func testStandardEncodingAndDecoding() throws {
        let mock = RouteMock(route: detailScreen)
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(RouteMock.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testSomeOptionalEncodingAndDecoding() throws {
        let mock = OptionalRouteMock(route: detailScreen)
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(OptionalRouteMock.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testNoneOptionalEncodingAndDecoding() throws {
        let mock = OptionalRouteMock(route: nil)
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(OptionalRouteMock.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testArrayEncodingAndDecoding() throws {
        let mock = ArrayMock(routes: [detailScreen, detailScreen, homeScreen])
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(ArrayMock.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testDictionaryEncodingAndDecoding() throws {
        let mock = DictionaryMock(routes: [detailScreen, detailScreen, homeScreen])
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(DictionaryMock.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    static var allTests = [
        ("testStandardEncodingAndDecoding", testStandardEncodingAndDecoding),
        ("testSomeOptionalEncodingAndDecoding", testSomeOptionalEncodingAndDecoding),
        ("testNoneOptionalEncodingAndDecoding", testNoneOptionalEncodingAndDecoding),
        ("testArrayEncodingAndDecoding", testArrayEncodingAndDecoding),
        ("testDictionaryEncodingAndDecoding", testDictionaryEncodingAndDecoding)
    ]
}

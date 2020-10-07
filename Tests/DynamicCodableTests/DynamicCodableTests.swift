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

    func testOptionalEncodingAndDecodingWithSomeValue() throws {
        let mock = OptionalRouteMock(route: detailScreen)
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(OptionalRouteMock.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testOptionalDecodingWithNullValue() throws {
        let json = """
        {
            "route": null
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(OptionalRouteMock.self, from: json)

        XCTAssertNil(decoded.route)
    }

    func testOptionalDecodingWithSomeValue() throws {
        let mock = OptionalRouteMockWithOptionalDynamicCodableProperty(route: detailScreen)
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(OptionalRouteMockWithOptionalDynamicCodableProperty.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testOptionalDecodingWithNilValue() throws {
        let mock = OptionalRouteMockWithOptionalDynamicCodableProperty(route: nil)
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(OptionalRouteMockWithOptionalDynamicCodableProperty.self, from: encoded)

        XCTAssertEqual(mock, decoded)
    }

    func testOptionalPropertyWrapperDecodingWithNoValueThrowsErrorAsPropertyWrapperItselfIsNotNil() throws {
        let json = "{}".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(OptionalRouteMock.self, from: json))
    }

    func testOptionalDecodingWithoutPropertyWrapperWithNullValue() throws {
        let json = """
        {
            "route": null
        }
        """.data(using: .utf8)!

        let decoded = try decoder.decode(OptionalRouteMockWithOptionalDynamicCodableProperty.self, from: json)

        XCTAssertNil(decoded.route)
    }

    func testOptionalDecodingWithoutPropertyWrapperWithNoValue() throws {
        let json = "{}".data(using: .utf8)!

        XCTAssertNoThrow(try decoder.decode(OptionalRouteMockWithOptionalDynamicCodableProperty.self, from: json))
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

    func testArrayEncodingAndDecodingWithUnknownValue() throws {
        let mock = ArrayMock(routes: [detailScreen, UnknownRoute(), homeScreen])
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(ArrayMock.self, from: encoded)

        XCTAssertEqual(decoded.routes.count, 2)
        XCTAssertEqual(decoded.routes[0].type, mock.routes[0].type)
        XCTAssertEqual(decoded.routes[1].type, mock.routes[2].type)
    }

    func testDictionaryEncodingAndDecodingWithUnknownValue() throws {
        let mock = DictionaryMock(routes: [detailScreen, UnknownRoute(), homeScreen])
        let encoded = try encoder.encode(mock)
        let decoded = try decoder.decode(DictionaryMock.self, from: encoded)

        XCTAssertEqual(decoded.routes.count, 2)
        XCTAssertEqual(decoded.routes[detailScreen.type]?.type, detailScreen.type)
        XCTAssertEqual(decoded.routes[homeScreen.type]?.type, homeScreen.type)
    }

    static var allTests = [
        ("testStandardEncodingAndDecoding", testStandardEncodingAndDecoding),
        ("testOptionalEncodingAndDecodingWithSomeValue", testOptionalEncodingAndDecodingWithSomeValue),
        ("testOptionalDecodingWithNullValue", testOptionalDecodingWithNullValue),
        ("testOptionalDecodingWithSomeValue", testOptionalDecodingWithSomeValue),
        ("testOptionalDecodingWithNilValue", testOptionalDecodingWithNilValue),
        ("testOptionalPropertyWrapperDecodingWithNoValueThrowsErrorAsPropertyWrapperItselfIsNotNil", testOptionalPropertyWrapperDecodingWithNoValueThrowsErrorAsPropertyWrapperItselfIsNotNil),
        ("testOptionalDecodingWithoutPropertyWrapperWithNullValue", testOptionalDecodingWithoutPropertyWrapperWithNullValue),
        ("testOptionalDecodingWithoutPropertyWrapperWithNoValue", testOptionalDecodingWithoutPropertyWrapperWithNoValue),
        ("testArrayEncodingAndDecoding", testArrayEncodingAndDecoding),
        ("testDictionaryEncodingAndDecoding", testDictionaryEncodingAndDecoding),
        ("testArrayEncodingAndDecodingWithUnknownValue", testArrayEncodingAndDecodingWithUnknownValue),
        ("testDictionaryEncodingAndDecodingWithUnknownValue", testDictionaryEncodingAndDecodingWithUnknownValue)
    ]
}

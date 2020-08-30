import XCTest
@testable import DynamicCodable

final class DynamicCodableTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        DynamicDecodableRegistry.register(DetailScreenRoute.self, typeIdentifier: DetailScreenRoute.type)
        DynamicDecodableRegistry.register(HomeScreenRoute.self, typeIdentifier: HomeScreenRoute.type)
    }

    func testEncodingAndDecoding() throws {
        let overview = HomeScreen(
            routes: [
                DetailScreenRoute(id: .init()),
                DetailScreenRoute(id: .init())
            ],
            route: HomeScreenRoute()
            )
        let encoded = try JSONEncoder().encode(overview)
        let decoded = try JSONDecoder().decode(HomeScreen.self, from: encoded)

        XCTAssertEqual(overview, decoded)
    }

    static var allTests = [
        ("testEncodingAndDecoding", testEncodingAndDecoding),
    ]
}

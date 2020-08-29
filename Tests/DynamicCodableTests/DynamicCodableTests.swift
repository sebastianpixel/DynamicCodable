import XCTest
@testable import DynamicCodable

final class DynamicCodableTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        DynamicDecodableRegistry.register(DetailScreenRoute.self)
        DynamicDecodableRegistry.register(HomeScreenRoute.self)
    }

    func testEncodingAndDecoding() throws {
        let overview = OverviewScreen(routes: [DetailScreenRoute(id: .init()), HomeScreenRoute()], route: HomeScreenRoute())
        let encoded = try JSONEncoder().encode(overview)
        let decoded = try JSONDecoder().decode(OverviewScreen.self, from: encoded)

        XCTAssertEqual(overview, decoded)
    }

    static var allTests = [
        ("testEncodingAndDecoding", testEncodingAndDecoding),
    ]
}

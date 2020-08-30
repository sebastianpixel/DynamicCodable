import DynamicCodable
import Foundation

protocol Route: DynamicCodableProtocol {
    static var type: String { get }
}

struct HomeScreenRoute: Route, Codable, Equatable {
    static let type = "homescreen"

    let type: String

    init() {
        type = Self.type
    }
}

struct DetailScreenRoute: Route, Codable, Equatable {
    static let type = "detailscreen"

    let id: UUID
    let type: String

    init(id: UUID) {
        self.id = id
        type = Self.type
    }
}

struct HomeScreen: Codable, Equatable {
    @DynamicCodable var routes: [Route]
    @DynamicCodable var route: Route

    init(routes: [Route], route: Route) {
        _routes = DynamicCodable(wrappedValue: routes)
        _route = DynamicCodable(wrappedValue: route)
    }
}

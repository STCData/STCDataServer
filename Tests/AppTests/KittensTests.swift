@testable import App
import XCTVapor

final class KittenTests: XCTestCase {
    func testFetchKittens() throws {
        let app = Application(.testing)
        defer {
            app.mongoDB.cleanup()
            app.shutdown()

        }
        try configure(app)

        try app.test(.POST, "kittens", beforeRequest: { req in
            try req.content.encode(["name":"test Kitten", "color": "black"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        try app.test(.GET, "kittens", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            // test that the extended JSON we get can be decoded into `Kitten`s.
            XCTAssertNoThrow(try res.content.decode([Kitten].self))
        })
    }
}

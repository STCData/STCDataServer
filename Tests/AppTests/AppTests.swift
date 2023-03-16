@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testFetchKittens() throws {
        let app = Application(.testing)
        defer {
            // app.mongoDB.cleanup()
            app.shutdown()
        }
        try configure(app)
        //should be launched with
        //   docker run -d -p 27017:27017 --name test-mongo mongo:latest
        // try app.mongoDB.configure("mongodb://localhost:27017")

        try app.test(.POST, "", beforeRequest: { req in
            try req.content.encode(["name":"test Kitten", "color": "black"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        try app.test(.GET, "", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            // test that the extended JSON we get can be decoded into `Kitten`s.
            XCTAssertNoThrow(try res.content.decode([Kitten].self))
            let kitten = try res.content.decode([Kitten].self).first
            XCTAssertEqual(kitten?.color, "black")
        })
    }
}

@testable import App
import XCTVapor
import SwiftAvroCore



struct Kitty: Codable, Equatable {
    enum KittyColor: String, Codable, CaseIterable {
        case Brown
        case White
        case Black
    }
    let name: String
    let color: KittyColor
    
    static func random() -> Self {
        Self(name:[
            "Whiskers",
            "Felix",
            "Oscar",
            "Smudge",
            "Fluffy",
            "Angel",
            "Lady",
            "Lucky"
        ].randomElement()!
             , color:KittyColor.allCases.randomElement()!
        )
    }
}


struct KittyAction: Codable, Equatable {
    enum KittyActionType:  String, Codable, CaseIterable {
        case meow
        case jump
        case bite
    }
    let label: String
    let type: KittyActionType
    let timestamp: Date
    let intValue: Int
    let floatValue: Float
    let doubleValue: Double
    let kitty: Kitty
    
    static func random() -> Self {
        Self(label: [
            "yah just kidding",
            "random text",
            "very very very very very very long label",
            "hahahhhahah"
        ].randomElement()!, type: KittyActionType.allCases.randomElement()!,
             timestamp: Date(),
             intValue: Int.random(in: -100...4990),
             floatValue: Float.random(in: -1000...40),
             doubleValue: Double.random(in: -100...40),
             kitty: Kitty.random())
    }
}

final class KittenActionsTests: XCTestCase {
    func testKittenActions() throws {
        let app = Application(.testing)
        defer {
            app.shutdown()
        }
        try configure(app)
        
        let actions = (1...10).map { _ in
            KittyAction.random()
        }
        

        
        
        let codec = Codec()
        let avro = Avro()
        
        let schema = AvroSchema.reflecting(actions.first!)!
        let schemaString = try! String(decoding: avro.encodeSchema(schema: schema), as: UTF8.self)
        var oc = try! avro.makeFileObjectContainer(schema: schemaString, codec: codec)
        
        try oc.addObjects(actions)
        
        let data = try oc.encodeObject()

        
        
        
        try app.test(.POST, "data/kittenActions/", beforeRequest: { req in
            
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "application/avro")

            req.headers = headers
            req.body.writeData(data)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }
        

    
    func XtestKittenActionsWS() throws {
        let app = Application(.testing)
        defer {
            app.shutdown()
        }
        try configure(app)

        let port = 80
        
//        XCTAssertNotNil(app.http.server.shared.localAddress)
//        guard let localAddress = app.http.server.shared.localAddress,
//              let port = localAddress.port else {
//            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
//            return
//        }
//        
        let promise = app.eventLoopGroup.next().makePromise(of: String.self)
        WebSocket.connect(
            to: "ws://localhost:\(port)/data/kittenActions/ws",
            on: app.eventLoopGroup.next()
        ) { ws in
            // do nothing
            ws.onText { ws, string in
                promise.succeed(string)
            }
        }.cascadeFailure(to: promise)

        try XCTAssertEqual(promise.futureResult.wait(), "foo")

    }
}

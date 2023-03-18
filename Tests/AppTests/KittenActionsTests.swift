@testable import App
import XCTVapor
import SwiftAvroCore
import Foundation


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
    let timestamp: TimeInterval
    let createdAt: Date
    let intValue: Int
    let doubleValue: Double
    let kitty: Kitty
    
    static func random() -> Self {
        Self(label: [
            "yah just kidding",
            "random text",
            "very very very very very very long label",
            "hahahhhahah"
        ].randomElement()!, type: KittyActionType.allCases.randomElement()!,
             timestamp: Date().timeIntervalSince1970,
             createdAt: Date(),
             intValue: Int.random(in: -100...4990),
             doubleValue: Double.random(in: -100...40),
             kitty: Kitty.random())
    }
}

final class KittenActionsTests: XCTestCase {
    func makeAvroHeaders() -> HTTPHeaders{
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/avro")
        return headers
    }
    
    func makeSimpleActionsData() throws -> Data {
        
        struct SimpleAction: Codable {
            var a: UInt64 = 1
            var b: String = "hello"
        }
        
        let actions = (1...10).map { i in
            SimpleAction(a: i, b: "hello #\(i)")
        }
        
        let codec = Codec()
        let avro = Avro()
        
        let schema = AvroSchema.reflecting(actions.first!)!
        let schemaString = try! String(decoding: avro.encodeSchema(schema: schema), as: UTF8.self)
        var oc = try! avro.makeFileObjectContainer(schema: schemaString, codec: codec)
        
        try oc.addObjects(actions)
        
        return try oc.encodeObject()
    }
    
    
    func makeKittyActionsData() throws -> Data {
        
        let actions = (1...10).map { _ in
            KittyAction.random()
        }
        
        let codec = Codec()
        let avro = Avro()
        
        let schema = AvroSchema.reflecting(actions.first!)!
        let schemaString = try! String(decoding: avro.encodeSchema(schema: schema), as: UTF8.self)
        var oc = try! avro.makeFileObjectContainer(schema: schemaString, codec: codec)
        
        try oc.addObjects(actions)
        
        return try oc.encodeObject()
    }

    
    
    func testKittenActions() throws {
        
        let dbName = "kittens"
        let colName = "kittenActions"
        let apiPath = "data/\(dbName)/\(colName)/"
        
        let app = Application(.testing)
        defer {
            app.mongoDB.cleanup()
            app.shutdown()
        }
        try configure(app)
        let _ = app.mongoDB.client.db(dbName).drop()

        let data = try makeKittyActionsData()
        try app.test(.POST, apiPath, beforeRequest: { req in
            req.headers = makeAvroHeaders()
            req.body.writeData(data)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
        
        
        let data2 = try makeKittyActionsData()
        try app.test(.POST, apiPath, beforeRequest: { req in
            req.headers = makeAvroHeaders()
            req.body.writeData(data2)
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

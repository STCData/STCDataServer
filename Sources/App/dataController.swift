import MongoKitten
import Vapor
import SwiftAvroCore

extension Request {
    var collectionName: String {
        self.parameters.get("collection")!
    }
    
    var collection: MongoCollection {
        return self.application.db[self.collectionName]
    }
}


struct DataController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let data = routes.grouped("data")
        data.webSocket("ws", onUpgrade: webSocket)

        data.group(":collection") { dataCollection in
            dataCollection.webSocket("ws", onUpgrade: webSocket)
            dataCollection.post("", use: create)
        }
        
    }
    
    func webSocket(req: Request, ws: WebSocket) async -> () {
        ws.onText { ws, text in
            // String received by this WebSocket.
            print(text)
        }

        ws.onBinary { ws, binary in
            // [UInt8] received by this WebSocket.
            print(binary)
        }

    }
    
    func create(req: Request) async throws -> Response {
        
        let codec = Codec()
        let avro = Avro()
        var oc = try! avro.makeFileObjectContainer(schema: """
    {
    "type": "record",
    "name": "\(req.collectionName)",
    "fields" : []
    }
    """, codec: codec)
        
        let contentType = req.headers["Content-Type"]
//        guard contentType.contains("image/png") else { return }
        let buffer = req.body.data!
        let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes)!
        
        try oc.decodeHeader(from: data)

        // decode objec
        let start = oc.findMarker(from: data)
        try oc.decodeBlock(from: data.subdata(in: start..<data.count))

        let blockData = oc.blocks[0].data

//        var newKitten = try req.content.decode(Kitten.self)
//        newKitten.createdAt = Date()
//        let encoder = BSONEncoder()
//        let encodedKitten: Document = try encoder.encode(newKitten)
//        try await req.collection.insert(encodedKitten)
        return Response(status: .created)
    }

}

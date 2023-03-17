import MongoDBVapor
import Vapor
import SwiftAvroCore
//import BSON

extension Request {
    var collectionName: String {
        self.parameters.get("collection")!
    }
    
    var collection: MongoCollection<BSONDocument> {
        self.application.mongoDB.client.db("data").collection(collectionName, withType: BSONDocument.self)
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
        var oc = try AvroDecoder.makeObjectContrainer()
        let buffer = req.body.data!
        let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes)!
        
        try oc.decodeHeader(from: data)
        let start = oc.findMarker(from: data)
        let blockData = data.subdata(in: start..<data.count)
        try oc.decodeBlock(from: blockData)

        let decodedObjects: [[String: Any?]] = try oc.decodeObjects() as! [[String: Any?]]
        
        for obj in decodedObjects {
            let doc = try obj.toBSONDocument()
            let json = doc.toExtendedJSONString()
            print("\(json)")
            try await req.collection.insertOne(doc)
        }

        return Response(status: .created)
    }

}

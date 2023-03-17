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


private extension Dictionary {
    func castToEncodable() -> Dictionary<String, Encodable> {
        var result = [String: Encodable]()
        
        for (key, value) in self {
            if let nestedDict = value as? [String: Any] {
                result[key as! String] = nestedDict.castToEncodable() as? any Encodable
            } else if let castValue = value as? Encodable {
                result[key as! String] = castValue
            }
        }
        
        return result
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

        let decodedObjects: [[String: Any]] = try oc.decodeObjects() as! [[String: Any]]
        
        for obj in decodedObjects {
            let castedObj = obj.castToEncodable()
            let primitiveObj = castedObj as! [String: any Primitive]
            let document: Document = Document(elements:Array(primitiveObj))
            try await req.collection.insert(document)
        }

        return Response(status: .created)
    }

}

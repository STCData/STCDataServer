import MongoDBVapor
import SwiftAvroCore
import Vapor

private enum DocFields: String {
    case timeField = "time"
    case metaField = "meta"
    case metaAvroSchemaField = "avro"
    case metaClientField = "client"
    case metaClientOsField = "os"
}

// fixme mongo swift hides proper initializer, what else to do?
extension TimeseriesOptions {
    private static func createFromJSON(_ data: Data) -> Self? {
        guard let f = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        return f
    }

    static func from(timeField: String, metaField: String, granularity: Granularity) -> Self {
        let json = """
        {"timeField": "\(timeField)",
        "metaField": "\(metaField)",
        "granularity": "\(granularity.rawValue)"
        }
        """
        let jsonData = json.data(using: .utf8)!
        return Self.createFromJSON(jsonData)!
    }
}

extension Request {
    var collectionName: String {
        parameters.get("collection")!
    }

    var dbName: String {
        parameters.get("db")!
    }

    func makeCollection() async throws -> MongoCollection<BSONDocument> {
        let db = application.mongoDB.client.db(dbName)

        let to = TimeseriesOptions.from(
            timeField: DocFields.timeField.rawValue,
            metaField: DocFields.metaField.rawValue,
            granularity: TimeseriesOptions.Granularity.seconds
        )
        do {
            let collection = try await db.createCollection(collectionName, options: CreateCollectionOptions(timeseries: to))
            return collection

        } catch let error as MongoError.CommandError where error.code == 48 {
            return db.collection(collectionName)
        }
    }
}

struct DataController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let data = routes.grouped("data")
        data.group(":db") { dataDb in
            dataDb.group(":collection") { dataCollection in
                dataCollection.webSocket("ws", onUpgrade: webSocket)
                dataCollection.post("", use: create)
            }
        }
    }

    func webSocket(req _: Request, ws: WebSocket) async {
        ws.onText { _, text in
            // String received by this WebSocket.
            print(text)
        }

        ws.onBinary { _, binary in
            // [UInt8] received by this WebSocket.
            print(binary)
        }
    }

    func create(req: Request) async throws -> Response {
        var oc = try AvroDecoder.makeObjectContrainer()
        let buffer = req.body.data!
        let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes)!

        try oc.decodeHeader(from: data)

        let avroSchemaJson = oc.header.schema

        let avroSchemaDoc = try BSONDocument(fromJSON: avroSchemaJson)

        let start = oc.findMarker(from: data)
        let blockData = data.subdata(in: start ..< data.count)
        try oc.decodeBlock(from: blockData)

        let decodedObjects: [[String: Any?]] = try oc.decodeObjects() as! [[String: Any?]]

        for obj in decodedObjects {
            var doc = try obj.toBSONDocument()

            if let createdAt = doc["createdAt"] {
                doc[DocFields.timeField.rawValue] = createdAt
            } else {
                doc[DocFields.timeField.rawValue] = .datetime(Date.now)
            }

            doc[DocFields.metaField.rawValue] = [
                DocFields.metaClientField.rawValue: [DocFields.metaClientOsField.rawValue: "linux"],
                DocFields.metaAvroSchemaField.rawValue: .document(avroSchemaDoc),
            ]

            let json = doc.toExtendedJSONString()
            print("\(json)")

            try await req.makeCollection().insertOne(doc)
        }

        return Response(status: .created)
    }
}

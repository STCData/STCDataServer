import MongoKitten
import Vapor

/// A type matching the structure of documents in the corresponding MongoDB collection.
struct Kitten: Content, Codable {
    // let _id: BSONObjectID?
    let name: String
    let color: String
    var createdAt: Date?
}

extension Request {
    /// Convenience accessor for the home.kittens collection.
    var kittens: MongoCollection {
        self.application.db["kittens"]
    }
}

func routes(_ app: Application) throws {
    // A GET request will return a list of all kittens in the database.
    app.get { req async throws -> [Kitten] in
        try await req.kittens.find().decode(Kitten.self).drain()
    }

    // A POST request will create a new kitten in the database.
    app.post { req async throws -> Response in
        var newKitten = try req.content.decode(Kitten.self)
        newKitten.createdAt = Date()
        let encoder = BSONEncoder()
        let encodedKitten: Document = try encoder.encode(newKitten)
        try await req.kittens.insert(encodedKitten)
        return Response(status: .created)
    }
}

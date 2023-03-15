import MongoDBVapor
import Vapor

/// A type matching the structure of documents in the corresponding MongoDB collection.
struct Kitten: Content {
    let _id: BSONObjectID?
    let name: String
    let color: String
    var createdAt: Date?
}

extension Request {
    /// Convenience accessor for the home.kittens collection.
    var kittenCollection: MongoCollection<Kitten> {
        self.application.mongoDB.client.db("home").collection("kittens", withType: Kitten.self)
    }
}

func routes(_ app: Application) throws {
    // A GET request will return a list of all kittens in the database.
    app.get { req async throws -> [Kitten] in
        try await req.kittenCollection.find().toArray()
    }

    // A POST request will create a new kitten in the database.
    app.post { req async throws -> Response in
        var newKitten = try req.content.decode(Kitten.self)
        newKitten.createdAt = Date()
        try await req.kittenCollection.insertOne(newKitten)
        return Response(status: .created)
    }
}

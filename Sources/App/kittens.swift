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

struct KittensController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let kittens = routes.grouped("kittens")
        kittens.get(use: index)
        kittens.post(use: create)

        // kittens.group(":id") { todo in
        //     kittens.get(use: show)
        //     kittens.put(use: update)
        //     kittens.delete(use: delete)
        // }
    }

    func index(req: Request) async throws -> [Kitten] {
        try await req.kittens.find().decode(Kitten.self).drain()
    }

    func create(req: Request) async throws -> Response {
        var newKitten = try req.content.decode(Kitten.self)
        newKitten.createdAt = Date()
        let encoder = BSONEncoder()
        let encodedKitten: Document = try encoder.encode(newKitten)
        try await req.kittens.insert(encodedKitten)
        return Response(status: .created)
    }
/*
    func show(req: Request) throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.internalServerError)
        }
        // ...
    }

    func update(req: Request) throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.internalServerError)
        }
        // ...
    }

    func delete(req: Request) throws -> String {
        guard let id = req.parameters.get("id") else {
            throw Abort(.internalServerError)
        }
        // ...
    }
    */
}
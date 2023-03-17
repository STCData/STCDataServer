import MongoDBVapor
import Vapor
//import BSON

struct Kitten: Content, Codable {
    // let _id: BSONObjectID?
    let name: String
    let color: String
    var createdAt: Date?
}


extension Request {
    var kittenCollection: MongoCollection<Kitten> {
        self.application.mongoDB.client.db("home").collection("kittens", withType: Kitten.self)
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
        try await req.kittenCollection.find().toArray()
    }

    func create(req: Request) async throws -> Response {
        let newKitten = try req.content.decode(Kitten.self)
        try await req.kittenCollection.insertOne(newKitten)
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

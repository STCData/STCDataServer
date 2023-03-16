import MongoKitten
import Vapor


struct KittensController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let data = routes.grouped("data")
        data.webSocket(use:webSocket)
        // kittens.get(use: index)
        // kittens.post(use: create)

        // kittens.group(":id") { todo in
        //     kittens.get(use: show)
        //     kittens.put(use: update)
        //     kittens.delete(use: delete)
        // }
    }

    func webSocket(req: Request, ws: WebSocket) async throws -> [Kitten] {
        try await req.kittens.find().decode(Kitten.self).drain()
    }
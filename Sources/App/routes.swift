

import MongoDBVapor
import Vapor



func routes(_ app: Application) throws {
    try app.register(collection: KittensController())
    try app.register(collection: DataController())
}


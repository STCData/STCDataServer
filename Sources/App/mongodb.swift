import MongoKitten
import Vapor

extension Request {
    public var db: MongoDatabase {
        return application.db.adoptingLogMetadata([
            "request-id": .string(id)
        ])
    }
}

private struct MongoDBStorageKey: StorageKey {
    typealias Value = MongoDatabase
}

extension Application {
    public var db: MongoDatabase {
        get {
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }
    
    public func initializeMongoDB(connectionString: String) throws {
        self.db = try MongoDatabase.lazyConnect(to: connectionString)
    }
}

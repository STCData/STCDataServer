//
//  File.swift
//  
//
//  Created by standard on 3/18/23.
//

import Foundation
import MongoDBVapor


public extension BSON {
    static func from(_ value: Any) throws -> BSON {
        switch value {
        case let dict as [String: Any?]:
            return .document(try dict.toBSONDocument())
        case let document as BSONDocument:
            return .document(document)
        case let int as Int:
            return .int32(Int32(int))
        case let int32 as Int32:
            return .int32(int32)
        case let int64 as Int64:
            return .int64(int64)
        case let decimal128 as BSONDecimal128:
            return .decimal128(decimal128)
        case let array as [Any]:
            return try array.toBSON()
        case let bool as Bool:
            return .bool(bool)
        case let date as Date:
            return .datetime(date)
        case let double as Double:
            return .double(double)
        case let string as String:
            return .string(string)
        case let symbol as BSONSymbol:
            return .symbol(symbol)
        case let timestamp as BSONTimestamp:
            return .timestamp(timestamp)
        case let binary as BSONBinary:
            return .binary(binary)
        case let regex as BSONRegularExpression:
            return .regex(regex)
        case let objectId as BSONObjectID:
            return .objectID(objectId)
        case let dbPointer as BSONDBPointer:
            return .dbPointer(dbPointer)
        case let code as BSONCode:
            return .code(code)
        case let codeWithScope as BSONCodeWithScope:
            return .codeWithScope(codeWithScope)
        case is NSNull, Optional<Any>.none:
            return .null
        default:
            throw fatalError()
        }
    }
}

extension Dictionary where Key == String, Value == Any? {
    func toBSONDocument() throws -> BSONDocument {
        var bsonDocument = BSONDocument()
        for (key, value) in self {
            if let unwrappedValue = value {
                let bsonValue = try BSON.from(unwrappedValue)
                bsonDocument[key] = bsonValue
            } else {
                bsonDocument[key] = .null
            }
        }
        return bsonDocument
    }
}

extension Array where Element: Any {
    func toBSON() throws -> BSON {
        let bsonArray = try self.map { try BSON.from($0) }
        return .array(bsonArray)
    }
}

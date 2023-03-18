//
//  File.swift
//
//
//  Created by standard on 3/18/23.
//

@testable import App
import MongoDBVapor
import XCTest

class BSONTests: XCTestCase {
    func testBSONFromBSONDocument() throws {
        let bsonDocument: BSONDocument = [
            "foo": .int32(42),
            "bar": .string("baz"),
            "qux": .bool(true),
            "quux": .null,
        ]

        let bson = try BSON.from(bsonDocument)
        XCTAssertEqual(bson, .document(bsonDocument))
    }

    func testBSONFromArray() throws {
        let array: [Any?] = [
            42,
            "baz",
            true,
            nil,
        ]

        let bson = try BSON.from(array)
        XCTAssertEqual(bson, .array([
            .int32(42),
            .string("baz"),
            .bool(true),
            .null,
        ]))
    }

    func testBSONFromInt32() throws {
        let int32: Int32 = 42

        let bson = try BSON.from(int32)
        XCTAssertEqual(bson, .int32(int32))
    }

    func testBSONFromInt64() throws {
        let int64: Int64 = 42

        let bson = try BSON.from(int64)
        XCTAssertEqual(bson, .int64(int64))
    }

    func xtestBSONFromDecimal128() throws {
        let decimal128 = try BSONDecimal128("0123456789abcdef0123456789abcdef")

        let bson = try BSON.from(decimal128)
        XCTAssertEqual(bson, .decimal128(decimal128))
    }

    func testBSONFromBool() throws {
        let bool = true

        let bson = try BSON.from(bool)
        XCTAssertEqual(bson, .bool(bool))
    }

    func testBSONFromDate() throws {
        let date = Date()

        let bson = try BSON.from(date)
        XCTAssertEqual(bson, .datetime(date))
    }

    func testBSONFromDouble() throws {
        let double = 42.0

        let bson = try BSON.from(double)
        XCTAssertEqual(bson, .double(double))
    }

    func testBSONFromString() throws {
        let string = "foo"

        let bson = try BSON.from(string)
        XCTAssertEqual(bson, .string(string))
    }

    func testBSONFromTimestamp() throws {
        let timestamp = BSONTimestamp(timestamp: 42, inc: 0)

        let bson = try BSON.from(timestamp)
        XCTAssertEqual(bson, .timestamp(timestamp))
    }

    func testBSONFromBinary() throws {
        let data = "foo".data(using: .utf8)!
        let binary = try BSONBinary(data: data, subtype: .generic)

        let bson = try BSON.from(binary)
        XCTAssertEqual(bson, .binary(binary))
    }

    func testNestedDocument4Levels() {
        let nestedDictionary: [String: Any?] = [
            "name": "John",
            "age": 35,
            "address": [
                "city": "New York",
                "state": "NY",
                "zip": 10001,
                "location": [
                    "latitude": 40.7128,
                    "longitude": -74.006,
                    "coordinates": [
                        [1, 2],
                        [3, 4],
                    ],
                ],
            ],
        ]
        let bsonDoc = try! nestedDictionary.toBSONDocument()

        XCTAssertEqual(bsonDoc["name"], BSON.string("John"))
        XCTAssertEqual(bsonDoc["age"], BSON.int32(35))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["city"], BSON.string("New York"))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["state"], BSON.string("NY"))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["zip"], BSON.int32(10001))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["location"]?.documentValue?["latitude"], BSON.double(40.7128))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["location"]?.documentValue?["longitude"], BSON.double(-74.006))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["location"]?.documentValue?["coordinates"]?.arrayValue?[0].arrayValue?[0], BSON.int32(1))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["location"]?.documentValue?["coordinates"]?.arrayValue?[0].arrayValue?[1], BSON.int32(2))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["location"]?.documentValue?["coordinates"]?.arrayValue?[1].arrayValue?[0], BSON.int32(3))
        XCTAssertEqual(bsonDoc["address"]?.documentValue?["location"]?.documentValue?["coordinates"]?.arrayValue?[1].arrayValue?[1], BSON.int32(4))
    }
}

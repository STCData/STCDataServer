//
//  File.swift
//
//
//  Created by standard on 3/17/23.
//

import Foundation
import SwiftAvroCore
import Vapor

public extension HTTPMediaType {
    static let avro = HTTPMediaType(type: "application", subType: "avro")
}

extension AvroDecoder {
    static func makeObjectContrainer() throws -> ObjectContainer {
        let codec = Codec()
        let avro = Avro()
        let oc = try! avro.makeFileObjectContainer(schema: """
        {
        "type": "record",
        "name": "xxx",
        "fields" : []
        }
        """, codec: codec)
        return oc
    }
}

struct AvroDecoder: ContentDecoder {
    func decode<D>(_: D.Type, from body: NIOCore.ByteBuffer, headers _: NIOHTTP1.HTTPHeaders) throws -> D where D: Decodable {
        let data = body.getData(at: body.readerIndex, length: body.readableBytes)!

        var oc = try Self.makeObjectContrainer()
        try oc.decodeHeader(from: data)

        let start = oc.findMarker(from: data)
        let blockData = data.subdata(in: start ..< data.count)
        try oc.decodeBlock(from: blockData)

        let decodedObjects: [D] = try (oc.decodeObjects()) as [D]

        let object = decodedObjects.first!

        return object
    }
}

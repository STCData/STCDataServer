//
//  File.swift
//  
//
//  Created by standard on 3/17/23.
//

import Foundation
import Vapor
import SwiftAvroCore

public extension HTTPMediaType {
    static let avro = HTTPMediaType(type: "application", subType: "avro")
}

struct AvroDecoder: ContentDecoder {
    func decode<D>(_ decodable: D.Type, from body: NIOCore.ByteBuffer, headers: NIOHTTP1.HTTPHeaders) throws -> D where D : Decodable {
        
        let codec = Codec()
        let avro = Avro()
        var oc = try! avro.makeFileObjectContainer(schema: """
    {
    "type": "record",
    "name": "xxx",
    "fields" : []
    }
    """, codec: codec)
        
        let data = body.getData(at: body.readerIndex, length: body.readableBytes)!
        
        try oc.decodeHeader(from: data)

        let start = oc.findMarker(from: data)
        let blockData = data.subdata(in: start..<data.count)
        try oc.decodeBlock(from: blockData)

        let blockDataDecoded = oc.blocks[0].data
        
        let result: D = try avro.decode(from: blockDataDecoded) as! D
        
        return result
    }
    
    
}

//
//  SwiftMultihash.swift
//  SwiftMultihash
//
//  Created by Teo on 18/05/15.
//  Copyright (c) 2015 Teo. All rights reserved.
//

import Foundation
import SwiftHex

/// Errors
let ErrDomain = "MultiHashDomain"
public let
ErrUnknownCode      = NSError(domain: ErrDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : "Unknown multihash code"]),
ErrTooShort         = NSError(domain: ErrDomain, code: -2, userInfo: [NSLocalizedDescriptionKey : "Multihash too short. Must be > 3 bytes"]),
ErrTooLong          = NSError(domain: ErrDomain, code: -3, userInfo: [NSLocalizedDescriptionKey : "Multihash too long. Must be < 129 bytes"]),
ErrLenNotSupported  = NSError(domain: ErrDomain, code: -4, userInfo: [NSLocalizedDescriptionKey : "Multihash does not yet support digests longer than 127 bytes"]),
ErrHexFail  = NSError(domain: ErrDomain, code: -5, userInfo: [NSLocalizedDescriptionKey : "Error occurred in hex conversion."])

func ErrInconsistentLen(dm: DecodedMultihash) -> NSError {
        return NSError(domain: ErrDomain, code: -6, userInfo: [NSLocalizedDescriptionKey : "Multihash length inconsistent: \(dm)"])
}

let
SHA1        = 0x11,
SHA2_256    = 0x12,
SHA2_512    = 0x13,
SHA3        = 0x14,
BLAKE2B     = 0x40,
BLAKE2S     = 0x41

public let Names: [String : Int] = [
    "sha1"      : SHA1,
    "sha2-256"  : SHA2_256,
    "sha2-512"  : SHA2_512,
    "sha3"      : SHA3,
    "blake2b"   : BLAKE2B,
    "blake2s"   : BLAKE2S
]

public let Codes: [Int : String] = [
    SHA1        : "sha1",
    SHA2_256    : "sha2-256",
    SHA2_512    : "sha2-512",
    SHA3        : "sha3",
    BLAKE2B     : "blake2b",
    BLAKE2S     : "blake2s"
]

let DefaultLengths: [Int : Int] = [
    SHA1        : 20,
    SHA2_256    : 32,
    SHA2_512    : 64,
    SHA3        : 64,
    BLAKE2B     : 64,
    BLAKE2S     : 32
]

public struct DecodedMultihash {
    public let
        code    : Int,
        name    : String?,
        length  : Int,
        digest  : [uint8]
}

public struct Multihash {
    public let value: [uint8]
}

extension Multihash {
    public func hexString() -> String {
        return SwiftHex.encodeToString(value)
    }
    
    public func string() -> String {
        return self.hexString()
    }
}

public func fromHexString(theString: String) -> (Multihash?, NSError?) {
    if let buf = SwiftHex.decodeString(theString) {
        return cast(buf)
    }
    return (nil, ErrHexFail)
}

public func cast(buf: [uint8]) -> (Multihash?, NSError?) {
    let (dm, err) = decode(buf)
    
    if err != nil {
        return (nil, err)
    }
    
    if validCode(dm!.code) == false {
        return (nil,ErrUnknownCode)
    }
    
    return (Multihash(value: buf),nil)
}

public func decode(buf: [uint8]) -> (DecodedMultihash?, NSError?) {

    if buf.count < 3 {
        return (nil, ErrTooShort)
    }
    if buf.count > 129 {
        return (nil, ErrTooLong)
    }

    let dm = DecodedMultihash(code: Int(buf[0]), name: Codes[Int(buf[0])], length: Int(buf[1]), digest: Array(buf[2..<buf.count]))
    
    if dm.digest.count != dm.length {
        return (nil, ErrInconsistentLen(dm))
    }
    return (dm, nil)
}

/// Encode a hash digest along with the specified function code
/// Note: The length is derived from the length of the digest.
public func encode(buf: [uint8], code: Int?) -> ([uint8]?, NSError?) {

    if validCode(code) == false {
        return (nil,ErrUnknownCode)
    }
    
    if buf.count > 129 {
        return (nil, ErrTooLong)
    }
    
    var pre = [0,0] as [uint8]
    
    pre[0] = uint8(code!)
    pre[1] = uint8(buf.count)
    pre.extend(buf)
    return (pre,nil)
}

public func encodeName(buf: [uint8], name: String) -> ([uint8]?,NSError?) {
    return encode(buf, Names[name])
}

/// ValidCode checks whether a multihash code is valid.
public func validCode(code: Int?) -> Bool {
    
    if let c = code {
        if appCode(c) == true {
            return true
        }
        
        if let ok = Codes[c] {
            return true
        }
    }
    return false
}

/// AppCode checks whether a multihash code is part of the App range.
public func appCode(code: Int) -> Bool {
    return code >= 0 && code < 0x10
}
//
//  KcSwiftTool.swift
//  LookinClient
//
//  Created by 张杰 on 2022/4/13.
//  Copyright © 2022 hughkli. All rights reserved.
//

import Cocoa

@objc(KcSwiftTool)
@objcMembers
public class KcSwiftTool: NSObject {
    
    
    /** symbol name -> 人类可读的Swift语言形式
     Convert a executable symbol name "mangled" according to Swift's
     conventions into a human readable Swift language form
     */
    @objc class func demangle(symbol: UnsafePointer<Int8>) -> String? {
        if let demangledNamePtr = _stdlib_demangleImpl(
            symbol, mangledNameLength: UInt(strlen(symbol)),
            outputBuffer: nil, outputBufferSize: nil, flags: 0) {
            let demangledName = String(cString: demangledNamePtr)
            free(demangledNamePtr)
            return demangledName
        }
        return nil
    }
}


@_silgen_name("swift_demangle")
private
func _stdlib_demangleImpl(
    _ mangledName: UnsafePointer<CChar>?,
    mangledNameLength: UInt,
    outputBuffer: UnsafeMutablePointer<UInt8>?,
    outputBufferSize: UnsafeMutablePointer<UInt>?,
    flags: UInt32
    ) -> UnsafeMutablePointer<CChar>?

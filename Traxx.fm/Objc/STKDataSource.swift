//
//  STKDataSource.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 23/5/21.
//

import Foundation
import AudioToolbox

protocol STKDataSourceDelegate: NSObject {
    func dataSourceDataAvailable(dataSource: STKDataSource)
    func dataSourceErrorOccured(dataSource: STKDataSource)
    func dataSourceEof(dataSource: STKDataSource)
    func dataSource(dataSource: STKDataSource, didReadStreamMetadata metadata: Dictionary)
}

class STKDataSource: NSObject {

    var supportsSeek: Bool {
        return true
    }
    var position: Int {// SInt64
        return 0
    }
    var length: Int {
        return 0
    }
    var hasBytesAvailable: Bool {
        return false
    }

    var durationHint: Double
    var delegate: STKDataSourceDelegate?
    var recordToFileUrl: URL

    func registerForEvents(runLoop: RunLoop) -> Bool {
        return false
    }
    
    func unregisterForEvents() { }
    
    func close() { }

    func seekToOffset(offset: Int) { }
    
    func readIntoBuffer(buffer: UInt8, withSize size: Int) -> Int {
        return -1
    }
    
    func audioFileTypeHint() -> AudioFileTypeID {
        return 0
    }
}

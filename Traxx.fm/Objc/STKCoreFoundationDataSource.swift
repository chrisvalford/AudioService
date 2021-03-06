//
//  STKCoreFoundationDataSource.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

//class CoreFoundationDataSourceClientInfo {
//    var readStreamRef: CFReadStream
//    var datasource: STKCoreFoundationDataSource
//}

class STKCoreFoundationDataSource: STKDataSource {
    
    public var stream: CFReadStream?
    
    var isInErrorState: Bool
    var eventsRunLoop: RunLoop?
    
    init() {}
    
    class func ReadStreamCallbackProc(stream: CFReadStream, eventType: CFStreamEventType, inClientInfo: STKCoreFoundationDataSource) {
        let datasource: STKCoreFoundationDataSource = inClientInfo // as STKCoreFoundationDataSource
        
        switch eventType {
        case .errorOccurred:
            datasource.errorOccured()
            
        case .endEncountered:
            datasource.eof()
            
        case .hasBytesAvailable:
            datasource.dataAvailable()
            
        case .openCompleted:
            datasource.openCompleted()
            
        default:
            break
        }
    }

    func dataAvailable() {
        self.delegate?.dataSourceDataAvailable(dataSource: self)
    }
    
    func eof() {
        self.delegate?.dataSourceEof(dataSource: self)
    }
    
    func errorOccured() {
        isInErrorState = true
        self.delegate?.dataSourceErrorOccured(dataSource: self)
    }
    
    deinit {
        if stream != nil {
            if eventsRunLoop != nil {
                unregisterForEvents()
            }
            close()
            stream = nil
        }
    }
    
    override func close() {
        if stream != nil {
            if eventsRunLoop != nil {
                unregisterForEvents()
            }
            CFReadStreamClose(stream)
            stream = nil
        }
    }
    
    func open() { }
    
    func seekToOffset(offset: Int64) { }
    
    func readIntoBuffer(buffer: inout [UInt8], withSize size: Int) -> Int {
        return CFReadStreamRead(stream, &buffer, size);
    }
    
    override func unregisterForEvents() {
        if stream != nil {
            CFReadStreamSetClient(stream, CFStreamEventType.hasBytesAvailable.rawValue | CFStreamEventType.errorOccurred.rawValue | CFStreamEventType.endEncountered.rawValue, nil, nil)
            CFReadStreamUnscheduleFromRunLoop(stream, eventsRunLoop?.getCFRunLoop(), CFRunLoopMode.commonModes)
        }
    }
    
    func reregisterForEvents() -> Bool {
        if eventsRunLoop != nil && stream != nil {
            var context = CFStreamClientContext(version: 0,
                                                info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                                                retain: nil,
                                                release: nil,
                                                copyDescription: nil)
            CFReadStreamSetClient(stream, CFStreamEventType.hasBytesAvailable.rawValue | CFStreamEventType.errorOccurred.rawValue | CFStreamEventType.endEncountered.rawValue, STKCoreFoundationDataSource.ReadStreamCallbackProc, &context)
            CFReadStreamScheduleWithRunLoop(stream, eventsRunLoop?.getCFRunLoop(), CFRunLoopMode.commonModes)
            return true
        }
        return false
    }
    
    override func registerForEvents(runLoop: RunLoop) -> Bool {
        eventsRunLoop = runLoop
        
        if stream == nil {
            // Will register when they open or seek
            return true
        }
        
        var context = CFStreamClientContext(version: 0,
                                            info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                                            retain: nil,
                                            release: nil,
                                            copyDescription: nil)
        CFReadStreamSetClient(stream, CFStreamEventType.hasBytesAvailable.rawValue | CFStreamEventType.errorOccurred.rawValue | CFStreamEventType.endEncountered.rawValue, ReadStreamCallbackProc, &context)
        
        CFReadStreamScheduleWithRunLoop(stream, eventsRunLoop?.getCFRunLoop(), CFRunLoopMode.commonModes)
        
        return true
    }
    
    func hasBytesAvailable() -> Bool {
        if stream == nil {
            return false
        }
        return CFReadStreamHasBytesAvailable(stream)
    }
    
    func status() -> CFStreamStatus {
        if stream != nil {
            return CFReadStreamGetStatus(stream)
        }
        //return 0
        return CFStreamStatus.notOpen
    }
    
    func openCompleted() {
    }
}

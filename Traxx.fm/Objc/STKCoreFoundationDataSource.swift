//
//  STKCoreFoundationDataSource.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

class CoreFoundationDataSourceClientInfo {
    var readStreamRef: CFReadStream
    var datasource: STKCoreFoundationDataSource
}

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
    
    func readIntoBuffer(buffer: [UInt8], withSize size: Int) -> Int {
        return CFReadStreamRead(stream, buffer, size);
    }
    
    override func unregisterForEvents() {
        if stream != nil {
            CFReadStreamSetClient(stream, .hasBytesAvailable | .errorOccurred | .endEncountered, NULL, NULL)
            CFReadStreamUnscheduleFromRunLoop(stream, eventsRunLoop.getCFRunLoop(), kCFRunLoopCommonModes)
        }
    }
    
    func reregisterForEvents() -> Bool {
        if eventsRunLoop != nil && stream != nil {
            let context: CFStreamClientContext = {0, self, NULL, NULL, NULL}
            CFReadStreamSetClient(stream, .hasBytesAvailable | .errorOccurred | .endEncountered, ReadStreamCallbackProc, &context)
            CFReadStreamScheduleWithRunLoop(stream, eventsRunLoop.getCFRunLoop(), kCFRunLoopCommonModes)
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
        
        let context: CFStreamClientContext = {0, self, NULL, NULL, NULL};
        
        CFReadStreamSetClient(stream, .hasBytesAvailable | .errorOccurred | .endEncountered, ReadStreamCallbackProc, &context)
        
        CFReadStreamScheduleWithRunLoop(stream, eventsRunLoop.getCFRunLoop(), kCFRunLoopCommonModes);
        
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

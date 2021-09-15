//
//  STKDataSourceWrapper.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 23/5/21.
//

import Foundation

class STKDataSourceWrapper: STKDataSource, STKDataSourceDelegate {

    init(WithDataSource innerDataSourceIn: STKDataSource) {
        self.innerDataSource = innerDataSourceIn;
        self.innerDataSource.delegate = self
    }
    
    var innerDataSource: STKDataSource

    func audioFileTypeHint() -> AudioFileTypeID {
        return self.innerDataSource.audioFileTypeHint;
    }

    deinit {
        self.innerDataSource.delegate = nil
    }

    func length() -> Int {
        return self.innerDataSource.length;
    }

    func seekToOffset(offset: Int) {
        return self.innerDataSource.seekToOffset(offset)
    }

    func readIntoBuffer(buffer: UInt8, withSize size: Int) -> Int {
        return self.innerDataSource.readIntoBuffer(buffer, withSize: size)
    }

    func position() -> Int {
        return self.innerDataSource.position
    }

    func registerForEvents(runLoop: NSRunLoop) -> Bool {
        return self.innerDataSource.registerForEvents(runLoop)
    }

    func unregisterForEvents() {
        self.innerDataSource.unregisterForEvents()
    }

    func close() {
        self.innerDataSource.close()
    }

    func hasBytesAvailable() -> Bool {
        return self.innerDataSource.hasBytesAvailable
    }

    func dataSourceDataAvailable(dataSource: STKDataSource) {
        self.delegate.dataSourceDataAvailable(self)
    }

    func dataSourceErrorOccured(dataSource: STKDataSource) {
        self.delegate.dataSourceErrorOccured(self)
    }

    func dataSourceEof(dataSource: STKDataSource) {
        self.delegate.dataSourceEof(self)
    }

    func dataSource(dataSource: STKDataSource, didReadStreamMetadata metadata: Dictionary) {
        self.delegate.dataSource(self, didReadStreamMetadata: metadata)
    }

}

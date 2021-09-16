//
//  STKFrameFilterEntry.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

typedef void(^STKFrameFilter)(channelsPerFrame: UInt32, bytesPerFrame: UInt32, frameCount: UInt32, frames: Void)

class STKFrameFilterEntry: NSObject {
    var name: String // RO
    var filter: STKFrameFilter // RO

    init(filter: STKFrameFilter, name: String) {
        super.init()
        self.filter = filterIn // copy
        self.name = name
    }
}

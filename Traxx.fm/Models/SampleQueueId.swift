//
//  SampleQueueId.swift
//  SwiftExample
//
//  Created by Christopher Alford on 18/5/21.
//  Copyright © 2021 Thong Nguyen. All rights reserved.
//

import Foundation

class SampleQueueId : NSObject {

    var count: Int
    var url: URL

    init(url: URL, count: Int) {
        self.url = url
        self.count = count
        super.init()
}

    func isEqual(object: Any?) -> Bool {
    if object == nil {
        return false
    }
    
    if !(object is SampleQueueId) {
        return false
    }
    
    return (object as! SampleQueueId).url == self.url && (object as! SampleQueueId).count == self.count
}

    func description() -> String {
        return url.description
    }
}

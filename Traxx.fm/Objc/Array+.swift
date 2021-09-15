//
//  Array+.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

extension Array {

    func enqueue(obj: AnyObject) {
        self.insert(obj, at: 0)
}

    func skipQueue(obj: AnyObject) {
        self.append(obj)
}

    func skipQueue(queue: Array) {
        self.append(contentsOf: queue)
}

    func dequeue() -> AnyObject?
{
    if ([self count] == 0)
    {
        return nil;
    }
    
    id retval = [self lastObject];
    
    [self removeLastObject];
    
    return retval;
}

func peek() -> AnyObject
{
    return [self lastObject];
}

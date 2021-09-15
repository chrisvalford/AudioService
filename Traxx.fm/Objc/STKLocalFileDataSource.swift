//
//  STKLocalFileDataSource.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation
import AudioToolbox

class STKLocalFileDataSource: STKCoreFoundationDataSource {

    private var position: Int64
    private var length: Int64
    private var _audioFileTypeHint: AudioFileTypeID

    var filePath: String


    init(filePath: String) {
        super.init()
        self.filePath = filePath
        audioFileTypeHint = STKLocalFileDataSource.audioFileTypeHintFrom(fileExtension: filePath.pathExtension)
    }

    class func audioFileTypeHintFrom(fileExtension: String) -> AudioFileTypeID {
    let fileTypesByFileExtensions = [
            ["mp3": kAudioFileMP3Type],
            ["wav": kAudioFileWAVEType],
            ["aifc": kAudioFileAIFCType],
            ["aiff": kAudioFileAIFFType],
            ["m4a": kAudioFileM4AType],
            ["mp4": kAudioFileMPEG4Type],
            ["caf": kAudioFileCAFType],
            ["aac": kAudioFileAAC_ADTSType],
            ["ac3": kAudioFileAC3Type],
            ["3gp": kAudioFile3GPType]
    ]
        if let number = fileTypesByFileExtensions[fileExtension] {
            return number // AudioFileTypeID
        }
        return 0;
    }

    func audioFileTypeHint() -> AudioFileTypeID {
        return _audioFileTypeHint
    }

    func close() {
        if stream != nil {
            unregisterForEvents()
            CFReadStreamClose(stream)
            stream = 0
        }
    }

    func open() {
    if stream != nil {
        unregisterForEvents()
        CFReadStreamClose(stream)
        CFRelease(stream)
        stream = 0
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath:self.filePath];
    
    stream = CFReadStreamCreateWithFile(NULL, (__bridge CFURLRef)url);
    
    NSError* fileError;
    NSFileManager* manager = [[NSFileManager alloc] init];
    NSDictionary* attributes = [manager attributesOfItemAtPath:filePath error:&fileError];

    if (fileError)
    {
        CFReadStreamClose(stream);
        CFRelease(stream);
        stream = 0;
        return;
    }

    NSNumber* number = [attributes objectForKey:@"NSFileSize"];
    
    if (number)
    {
        length = number.longLongValue;
    }
    
    [self reregisterForEvents];

    CFReadStreamOpen(stream);
}

-(SInt64) position
{
    return position;
}

-(SInt64) length
{
    return length;
}

-(int) readIntoBuffer:(UInt8*)buffer withSize:(int)size
{
    int retval = (int)CFReadStreamRead(stream, buffer, size);

    if (retval > 0)
    {
        position += retval;
    }
    else
    {
        NSNumber* property = (__bridge_transfer NSNumber*)CFReadStreamCopyProperty(stream, kCFStreamPropertyFileCurrentOffset);
        
        position = property.longLongValue;
    }
    
    return retval;
}

-(void) seekToOffset:(SInt64)offset
{
    CFStreamStatus status = kCFStreamStatusClosed;
    
    if (stream != 0)
    {
        status = CFReadStreamGetStatus(stream);
    }
    
    BOOL reopened = NO;
    
    if (status == kCFStreamStatusAtEnd || status == kCFStreamStatusClosed || status == kCFStreamStatusError)
    {
        reopened = YES;
        
        [self close];
        [self open];
    }
    
    if (stream == 0)
    {
        CFRunLoopPerformBlock(eventsRunLoop.getCFRunLoop, NSRunLoopCommonModes, ^
        {
            [self errorOccured];
        });
        
        CFRunLoopWakeUp(eventsRunLoop.getCFRunLoop);
        
        return;
    }
    
    if (CFReadStreamSetProperty(stream, kCFStreamPropertyFileCurrentOffset, (__bridge CFTypeRef)[NSNumber numberWithLongLong:offset]) != TRUE)
    {
        position = 0;
    }
    else
    {
        position = offset;
    }
    
    if (!reopened)
    {
        CFRunLoopPerformBlock(eventsRunLoop.getCFRunLoop, NSRunLoopCommonModes, ^
        {
            if ([self hasBytesAvailable])
            {
                [self dataAvailable];
            }
        });
        
        CFRunLoopWakeUp(eventsRunLoop.getCFRunLoop);
    }
}

-(NSString*) description
{
    return self->filePath;
}

@end


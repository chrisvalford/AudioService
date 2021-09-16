//
//  STKLocalFileDataSource.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation
import AudioToolbox

class STKLocalFileDataSource: STKCoreFoundationDataSource {

    private var position: Int
    private var length: Int
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

    override func close() {
        if stream != nil {
            unregisterForEvents()
            CFReadStreamClose(stream)
            stream = nil
        }
    }

    override func open() {
        if stream != nil {
            unregisterForEvents()
            CFReadStreamClose(stream)
            stream = nil
        }

        let url = URL(fileURLWithPath: self.filePath)
        stream = CFReadStreamCreateWithFile(nil, url) // CFURLRef

        let manager = FileManager()
        do {
            let attributes = try manager.attributesOfItem(atPath: filePath)
            if let number = attributes[FileAttributeKey(rawValue: "NSFileSize")] {
                length = number as! Int
            }
            reregisterForEvents()
            CFReadStreamOpen(stream)
        } catch {
            CFReadStreamClose(stream)
            stream = nil
            return
        }
    }

    override func readIntoBuffer(buffer: inout [UInt8], withSize size: Int) -> Int {
        let retval = CFReadStreamRead(stream, &buffer, size)
        if retval > 0 {
            position += retval;
        } else {
            let property = CFReadStreamCopyProperty(stream, CFStreamPropertyKey.fileCurrentOffset)
            position = property
        }
        return retval;
    }

    override func seekToOffset(offset: Int) {
        var status: CFStreamStatus = .closed

        if stream != nil {
            status = CFReadStreamGetStatus(stream)
        }

        var reopened = false

        if (status == CFStreamStatus.atEnd || status == CFStreamStatus.closed || status == CFStreamStatus.error) {
            reopened = true

            close()
            open()
        }

        if stream == nil {
            CFRunLoopPerformBlock(eventsRunLoop?.getCFRunLoop, NSRunLoopCommonModes, ^{
                self.errorOccured()
            });

            CFRunLoopWakeUp(eventsRunLoop?.getCFRunLoop);
            return
        }

        if CFReadStreamSetProperty(stream, kCFStreamPropertyFileCurrentOffset, offset) != true {
            position = 0
        } else {
            position = offset
        }
        if !reopened {
            CFRunLoopPerformBlock(eventsRunLoop?.getCFRunLoop, NSRunLoopCommonModes, ^ {
                if self.hasBytesAvailable() {
                    self.dataAvailable()
                }
            })
            CFRunLoopWakeUp(eventsRunLoop?.getCFRunLoop);
        }
    }

    func description() -> String {
        return filePath
    }

}


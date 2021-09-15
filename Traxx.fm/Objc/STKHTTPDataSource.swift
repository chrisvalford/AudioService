// STKHTTPDataSource.swift

import Foundation
import AudioToolbox

class STKHTTPDataSource: NSObject, STKCoreFoundationDataSource {
    
    var url: URL {
        return self.currentUrl
    }
    
    private (set) var httpStatusCode: Int
    
    private var supportsSeek: Bool
    private var httpStatusCode: Int
    private var seekStart: Int
    private var relativePosition: Int
    private var fileLength: Int
    private var discontinuous: Int
    private var requestSerialNumber: Int
    private var prefixBytesRead: Int
    private var prefixBytes: Data
    private var iceHeaderData: Data
    private var iceHeaderSearchComplete: Bool
    private var iceHeaderAvailable: Bool
    private var httpHeaderNotAvailable: Bool
    
    private var _metadataData: Data
    private var _metadataOffset: Int
    private var _metadataBytesRead: Int
    private var _metadataStep: Int
    private var _metadataLength: Int
    
    private var currentUrl: URL
    private var asyncUrlProvider: STKAsyncURLProvider
    private var httpHeaders: Dictionary
    private (set) var audioFileTypeHint: AudioFileTypeID
    private var requestHeaders: Dictionary
    
//    typedef void(^STKURLBlock)(NSURL* url);
//    typedef NSURL* _Nonnull (^STKURLProvider)(void);
//    typedef void(^STKAsyncURLProvider)(STKHTTPDataSource* dataSource, BOOL forSeek, STKURLBlock callback)

    -(instancetype) initWithURL:(NSURL*)url;
    
    -(nullable NSRunLoop*) eventsRunLoop;
    -(void) reconnect;
    
    -(void) open;
    
    init(urlIn: URL) {
        currentUrl = urlIn
        return init(urlProvider: URL) { // typedef NSURL* _Nonnull (^STKURLProvider)(void);
            return urlIn;
        }
    }
    
    init(urlIn: NSURL, httpRequestHeaders: Dictionary) {
        self = [self initWithURLProvider:^NSURL* { return urlIn; }];
        self.requestHeaders = httpRequestHeaders;
        return self;
    }
    
    init(urlProvider urlProviderIn: STKURLProvider) {
        urlProviderIn = urlProviderIn //copy
        
        return initWithAsyncURLProvider:^(STKHTTPDataSource* dataSource, BOOL forSeek, STKURLBlock block)
                {
            block(urlProviderIn());
        }
    }
    
    //True initializer
    init(asyncURLProvider asyncUrlProviderIn: STKAsyncURLProvider) {
        
            seekStart = 0
            relativePosition = 0
            fileLength = -1
            
            self.asyncUrlProvider = asyncUrlProviderIn //copy
            
        audioFileTypeHint = STKLocalFileDataSource.audioFileTypeHintFromFileExtension(self.currentUrl.pathExtension)
        
    }
    
    deinit {
        print("STKHTTPDataSource deinit");
    }
    
    
    class func audioFileTypeHintFromMimeType(mimeType: String) -> AudioFileTypeID {
    
        var fileTypesByMimeType = [
            "audio/mp3": kAudioFileMP3Type,
                "audio/mpg": kAudioFileMP3Type,
                "audio/mpeg": kAudioFileMP3Type,
                "audio/wav": kAudioFileWAVEType,
                "audio/x-wav": kAudioFileWAVEType,
                "audio/vnd.wav": kAudioFileWAVEType,
                "audio/aifc": kAudioFileAIFCType,
                "audio/aiff": kAudioFileAIFFType,
                "audio/x-m4a": kAudioFileM4AType,
                "audio/x-mp4": kAudioFileMPEG4Type,
                "audio/aacp": kAudioFileAAC_ADTSType,
                "audio/m4a": kAudioFileM4AType,
                "audio/mp4": kAudioFileMPEG4Type,
                "video/mp4": kAudioFileMPEG4Type,
                "audio/caf": kAudioFileCAFType,
                "audio/x-caf": kAudioFileCAFType,
                "audio/aac": kAudioFileAAC_ADTSType,
                "audio/ac3": kAudioFileAC3Type,
                "audio/3gp": kAudioFile3GPType,
                "video/3gp": kAudioFile3GPType,
                "audio/3gpp": kAudioFile3GPType,
                "video/3gpp": kAudioFile3GPType,
                "audio/3gp2": kAudioFile3GP2Type,
                "video/3gp2": kAudioFile3GP2Type]
        
        let number = fileTypesByMimeType.objectForKey(mimeType)
        
        if number == nil {
            return 0
        }
        return AudioFileTypeID(rawValue: number)
    }
    
    func parseIceHeader(headerData: Data) -> Dictionary<String, String> {
        let fullString = String(data: headerData, encoding: .utf8)
        let strings = fullString?.components(separatedBy: .newlines) //"\r\n"
        
        httpHeaders = dictionary()
        
        for  s in strings {
            if s.count == 0 {
                continue
            }
            
            if s.hasPrefix("ICY ") {
                let parts = s.components(separatedBy: " ")
                
                if parts.count >= 2 {
                    self.httpStatusCode = Int(parts[1])
                }
                continue
            }
            
            let range = s.rangeOfString(":")
            
            if range.location == NSNotFound {
                continue
            }
            
            let key = s.substringWithRange(.location = 0, .length = range.location)
            let value = s.substringFromIndex(range.location + 1)
            var retval = [String, String]()
            retval[key] = value
        }
        
        return retval
    }
    
    func parseHttpHeader() -> Bool {
        if !httpHeaderNotAvailable {
            let response: CFTypeRef = CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader)
            
            if response {
                httpHeaders = CFHTTPMessageCopyAllHeaderFields((response as? CFHTTPMessageRef))
                
                if httpHeaders.count == 0 {
                    httpHeaderNotAvailable = true
                } else {
                    self.httpStatusCode = CFHTTPMessageGetResponseStatusCode((response as? CFHTTPMessageRef))
                }
                CFRelease(response)
            }
        }
        
        if httpHeaderNotAvailable {
            if self.iceHeaderSearchComplete && !self.iceHeaderAvailable {
                return true
            }
            
            if !self.iceHeaderSearchComplete {
                var byte: UInt8
                let terminal1: [UInt8] = ["\n", "\n"]
                let terminal2: [UInt8] = ["\r", "\n", "\r", "\n"]
                
                if iceHeaderData == nil {
                    iceHeaderData = Data(capacity: 1024)
                }
                
                while true {
                    if !self.hasBytesAvailable {
                        break
                    }
                    
                    let read = super.readIntoBuffer(&byte, withSize: 1)
                    
                    if read <= 0 {
                        break
                    }
                    
                    iceHeaderData.appendBytes(&byte, length: read)
                    
                    if iceHeaderData.count >= sizeof(terminal1) {
                        if memcmp(&terminal1[0], [self.iceHeaderData bytes] + iceHeaderData.length - sizeof(terminal1), sizeof(terminal1)) == 0 {
                            self.iceHeaderAvailable = true
                            self.iceHeaderSearchComplete = true
                            break
                        }
                    }
                    
                    if iceHeaderData.length >= sizeof(terminal2) {
                        if memcmp(&terminal2[0], [self.iceHeaderData bytes] + iceHeaderData.length - sizeof(terminal2), sizeof(terminal2)) == 0 {
                            self.iceHeaderAvailable = true
                            self.iceHeaderSearchComplete = true
                            break
                        }
                    }
                    
                    if iceHeaderData.count >= 4 {
                        if memcmp([self.iceHeaderData bytes], "ICY ", 4) != 0 && memcmp([self.iceHeaderData bytes], "HTTP", 4) != 0 {
                            self.iceHeaderAvailable = false
                            self.iceHeaderSearchComplete = true
                            prefixBytes = iceHeaderData
                            return true
                        }
                    }
                }
                
                if !self.iceHeaderSearchComplete {
                    return false
                }
            }
            
            httpHeaders = self.parseIceHeader(self.iceHeaderData)
            
            self.iceHeaderData = nil
        }
        
        // check ICY headers
        if httpHeaders["Icy-metaint"] != nil {
            _metadataBytesRead  = 0
            _metadataStep       = Int(httpHeaders["Icy-metaint"])
            _metadataOffset     = _metadataStep
        }
        
        
        if httpHeaders["Accept-Ranges"]  != nil || httpHeaders["accept-ranges"] != nil {
            self.supportsSeek = httpHeaders["Accept-Ranges"] != "none"
        }
        
        if self.httpStatusCode == 200 {
            if seekStart == 0 {
                var value: String
                value = httpHeaders["Content-Length"]
                if value == nil {
                    value = httpHeaders["content-length"]
                }
                fileLength = Int(value)
            }
            
            let contentType = httpHeaders["Content-Type"] ?: [httpHeaders objectForKey:@"content-type"] ;
            AudioFileTypeID typeIdFromMimeType = [STKHTTPDataSource audioFileTypeHintFromMimeType:contentType];
            
            if (typeIdFromMimeType != 0)
            {
                audioFileTypeHint = typeIdFromMimeType;
            }
        }
        else if (self.httpStatusCode == 206)
        {
            NSString* contentRange = [httpHeaders objectForKey:@"Content-Range"] ?: [httpHeaders objectForKey:@"content-range"];
            NSArray* components = [contentRange componentsSeparatedByString:@"/"];
            
            if (components.count == 2)
            {
                fileLength = [[components objectAtIndex:1] integerValue];
            }
        }
        else if (self.httpStatusCode == 416)
        {
            if (self.length >= 0)
            {
                seekStart = self.length;
            }
            
            [self eof];
            
            return NO;
        }
        else if (self.httpStatusCode >= 300)
        {
            [self errorOccured];
            
            return NO;
        }
        
        return YES;
    }
    
    -(void) dataAvailable
    {
        if (stream == NULL)
        {
            return;
        }
        
        if (self.httpStatusCode == 0)
        {
            if ([self parseHttpHeader])
            {
                if ([self hasBytesAvailable])
                {
                    [super dataAvailable];
                }
                
                return;
            }
            else
            {
                return;
            }
        }
        else
        {
            [super dataAvailable];
        }
    }
    
    -(SInt64) position
    {
        return seekStart + relativePosition;
    }
    
    -(SInt64) length
    {
        return fileLength >= 0 ? fileLength : 0;
    }
    
    -(void) reconnect
    {
        NSRunLoop* savedEventsRunLoop = eventsRunLoop;
        
        [self close];
        
        eventsRunLoop = savedEventsRunLoop;
        
        [self seekToOffset:self.supportsSeek ? self.position : 0];
    }
    
    -(void) seekToOffset:(SInt64)offset
    {
        NSRunLoop* savedEventsRunLoop = eventsRunLoop;
        
        [self close];
        
        eventsRunLoop = savedEventsRunLoop;
        
        NSAssert([NSRunLoop currentRunLoop] == eventsRunLoop, @"Seek called on wrong thread");
        
        stream = 0;
        relativePosition = 0;
        seekStart = offset;
        
        self.isInErrorState = NO;
        
        if (!self.supportsSeek && offset != self.relativePosition)
        {
            return;
        }
        
        [self openForSeek:YES];
    }
    
    -(int) readIntoBuffer:(UInt8*)buffer withSize:(int)size
    {
        return [self privateReadIntoBuffer:buffer withSize:size];
    }
    
    //MARK - Custom buffer reading
    -(int) privateReadIntoBuffer:(UInt8*)buffer withSize:(int)size
    {
        if (size == 0)
        {
            return 0;
        }
        
        if (prefixBytes != nil)
        {
            int count = MIN(size, (int)prefixBytes.length - prefixBytesRead);
            
            [prefixBytes getBytes:buffer length:count];
            
            prefixBytesRead += count;
            
            if (prefixBytesRead >= prefixBytes.length)
            {
                prefixBytes = nil;
            }
            
            return count;
        }
        
        int read;
        
        // read ICY stream metadata
        // http://www.smackfu.com/stuff/programming/shoutcast.html
        //
        if(_metadataStep > 0)
        {
            // read audio stream before next metadata chunk
            if(_metadataOffset > 0)
            {
                read = [super readIntoBuffer:buffer withSize:MIN(_metadataOffset, size)];
                if(read > 0)
                    _metadataOffset -= read;
            }
            // read metadata
            else
            {
                // first we need to read one byte with length
                if(_metadataLength == 0)
                {
                    // read only 1 byte
                    UInt8 metadataLengthByte;
                    read = [super readIntoBuffer:&metadataLengthByte withSize:1];
                    
                    if(read > 0)
                    {
                        _metadataLength = metadataLengthByte * 16;
                        
                        // prepare
                        if(_metadataLength > 0)
                        {
                            _metadataData       = [NSMutableData dataWithLength:_metadataLength];
                            _metadataBytesRead  = 0;
                        }
                        // reset
                        else
                        {
                            _metadataOffset = _metadataStep;
                            _metadataData   = nil;
                            _metadataLength = 0;
                        }
                        
                        // return 0, because no audio bytes read
                        relativePosition += read;
                        read = 0;
                    }
                }
                // read metadata bytes
                else
                {
                    read = [super readIntoBuffer:(_metadataData.mutableBytes + _metadataBytesRead)
                                        withSize:_metadataLength - _metadataBytesRead];
                    
                    if(read > 0)
                    {
                        _metadataBytesRead += read;
                        
                        // done reading, so process it
                        if(_metadataBytesRead == _metadataLength)
                        {
                            if([self.delegate respondsToSelector:@selector(dataSource:didReadStreamMetadata:)])
                                [self.delegate dataSource:self didReadStreamMetadata:[self _processIcyMetadata:_metadataData]];
                            
                            // reset
                            _metadataData       = nil;
                            _metadataOffset     = _metadataStep;
                            _metadataLength     = 0;
                            _metadataBytesRead  = 0;
                        }
                        
                        // return 0, because no audio bytes read
                        relativePosition += read;
                        read = 0;
                    }
                }
            }
        }
        else
        {
            read = [super readIntoBuffer:buffer withSize:size];
        }
        
        if (read < 0)
            return read;
        
        relativePosition += read;
        
        return read;
    }
    
    -(void) open
    {
        return [self openForSeek:NO];
    }
    
    -(void) openForSeek:(BOOL)forSeek
    {
        int localRequestSerialNumber;
        
        requestSerialNumber++;
        localRequestSerialNumber = requestSerialNumber;
        
        asyncUrlProvider(self, forSeek, ^(NSURL* url)
                         {
            if (localRequestSerialNumber != self.requestSerialNumber)
            {
                return;
            }
            
            self.currentUrl = url;
            
            if (url == nil)
            {
                return;
            }
            
            CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (__bridge CFURLRef)self.currentUrl, kCFHTTPVersion1_1);
            
            if (self.seekStart > 0 && self.supportsSeek)
            {
                CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Range"), (__bridge CFStringRef)[NSString stringWithFormat:@"bytes=%lld-", self.seekStart]);
                
                self.discontinuous = YES;
            }
            
            for (NSString* key in self.requestHeaders)
            {
                NSString* value = [self.requestHeaders objectForKey:key];
                
                CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)value);
            }
            
            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Accept"), CFSTR("*/*"));
            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Icy-MetaData"), CFSTR("1"));
            
            self.stream = CFReadStreamCreateForHTTPRequest(NULL, message);
            
            if (self.stream == nil)
            {
                CFRelease(message);
                
                [self errorOccured];
                
                return;
            }
            
            CFReadStreamSetProperty(self.stream, (__bridge CFStringRef)NSStreamNetworkServiceTypeBackground, (__bridge CFStringRef)NSStreamNetworkServiceTypeBackground);
            
            if (!CFReadStreamSetProperty(self.stream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue))
            {
                CFRelease(message);
                
                [self errorOccured];
                
                return;
            }
            
            // Proxy support
            CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();
            CFReadStreamSetProperty(self.stream, kCFStreamPropertyHTTPProxy, proxySettings);
            CFRelease(proxySettings);
            
            // SSL support
            if ([self.currentUrl.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
            {
                NSDictionary* sslSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                             (NSString*)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,
                                             [NSNumber numberWithBool:NO], kCFStreamSSLValidatesCertificateChain,
                                             nil];
                CFReadStreamSetProperty(self.stream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)sslSettings);
            }
            
            [self reregisterForEvents];
            
            self.httpStatusCode = 0;
            
            // Open
            if (!CFReadStreamOpen(self.stream))
            {
                CFRelease(self.stream);
                CFRelease(message);
                
                self.stream = NULL;
                
                [self errorOccured];
                
                return;
            }
            
            self.isInErrorState = NO;
            
            CFRelease(message);
        });
    }
    
    -(UInt32) httpStatusCode
    {
        return self.httpStatusCode;
    }
    
    -(NSRunLoop*) eventsRunLoop
    {
        return self.eventsRunLoop;
    }
    
    -(NSString*) description
    {
        return [NSString stringWithFormat:@"HTTP data source with file length: %lld and position: %lld", self.length, self.position];
    }
    
    -(BOOL) supportsSeek
    {
        return self.supportsSeek;
    }
    
//MARK - Private
    
    - (NSDictionary*)_processIcyMetadata:(NSData*)data
    {
        NSMutableDictionary *metadata       = [NSMutableDictionary new];
        NSString            *metadataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray             *pairs          = [metadataString componentsSeparatedByString:@";"];
        
        for(NSString *pair in pairs)
        {
            NSArray *components = [pair componentsSeparatedByString:@"="];
            if(components.count < 2)
                continue;
            
            NSString *key   = components[0];
            NSString *value = [pair substringWithRange:NSMakeRange(key.length + 2, pair.length - (key.length + 2) - 1)];
            
            [metadata setValue:value forKey:key];
        }
        
        return metadata;
    }
    
}
}

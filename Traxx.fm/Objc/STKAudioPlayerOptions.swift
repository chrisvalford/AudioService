//
//  STKAudioPlayerOptions.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

///
/// Options to initiailise the Audioplayer with.
/// By default if you set buffer size or seconds to 0, the non-zero default will be used
/// If you would like to disable the buffer option completely set to STK_DISABLE_BUFFER
///
struct STKAudioPlayerOptions {
    /// If true then seeking a track will cause all pending items to be flushed from the queue
    var flushQueueOnSeek: Bool
    /// If true then volume control will be enabled on iOS
    var enableVolumeMixer: Bool
    /// A pointer to a 0 terminated array of band frequencies (iOS 5.0 and later, OSX 10.9 and later)
    var equalizerBandFrequencies: [Float32] // 24
    /// The size of the internal I/O read buffer. This data in this buffer is transient and does not need to be larger.
    var readBufferSize: UInt32
    /// The size of the decompressed buffer (Default is 10 seconds which uses about 1.7MB of RAM)
    var bufferSizeInSeconds: Float32
    /// Number of seconds of decompressed audio is required before playback first starts for each item (Default is 0.5 seconds. Must be larger than bufferSizeInSeconds)
    var secondsRequiredToStartPlaying: Float32
    /// Seconds after a seek is performed before data needs to come in (after which the state will change to playing/buffering)
    var gracePeriodAfterSeekInSeconds: Float32
    /// Number of seconds of decompressed audio required before playback resumes after a buffer underrun (Default is 5 seconds. Must be larger than bufferSizeinSeconds)
    var secondsRequiredToStartPlayingAfterBufferUnderun: Float32
}
;

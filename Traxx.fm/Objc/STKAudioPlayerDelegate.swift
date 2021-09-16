//
//  STKAudioPlayerDelegate.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

protocol STKAudioPlayerDelegate: NSObject {

/// Raised when an item has started playing
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: AnyObject)
/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: AnyObject)
/// Raised when the state of the player has changed
func audioPlayer(_ audioPlayer: STKAudioPlayer,
    stateChanged state: STKAudioPlayerState,
previousState: STKAudioPlayerState)
/// Raised when an item has finished playing
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: AnyObject,
                     withReason stopReason: STKAudioPlayerStopReason,
                     andProgress progress: Double,
                     andDuration duration: Double)
/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
    func audioPlayer(_ audioPlayer: STKAudioPlayer,
                     unexpectedError errorCode: STKAudioPlayerErrorCode)
//@optional
/// Optionally implemented to get logging information from the STKAudioPlayer (used internally for debugging)
func audioPlayer(_ audioPlayer: STKAudioPlayer, logInfo line: String)
/// Raised when items queued items are cleared (usually because of a call to play, setDataSource or stop)
func audioPlayer(_ audioPlayer: STKAudioPlayer, didCancelQueuedItems queuedItems: Array)

/// Raised when datasource read stream metadata. Called from the non-main thread.
func audioPlayer(_ audioPlayer: STKAudioPlayer, didReadStreamMetadata dictionary: Dictionary)

}

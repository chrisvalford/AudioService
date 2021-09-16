//
//  Enums.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 15/9/21.
//

import Foundation

enum STKAudioPlayerState: Int { // NS_OPTIONS
    case STKAudioPlayerStateReady,
    STKAudioPlayerStateRunning = 1,
    STKAudioPlayerStatePlaying = (1 << 1) | STKAudioPlayerStateRunning,
    STKAudioPlayerStateBuffering = (1 << 2) | STKAudioPlayerStateRunning,
    STKAudioPlayerStatePaused = (1 << 3) | STKAudioPlayerStateRunning,
    STKAudioPlayerStateStopped = (1 << 4),
    STKAudioPlayerStateError = (1 << 5),
    STKAudioPlayerStateDisposed = (1 << 6)
}

enum STKAudioPlayerStopReason: Int {
    case STKAudioPlayerStopReasonNone = 0,
    STKAudioPlayerStopReasonEof,
    STKAudioPlayerStopReasonUserAction,
    STKAudioPlayerStopReasonPendingNext,
    STKAudioPlayerStopReasonDisposed,
    STKAudioPlayerStopReasonError = 0xffff
}

enum STKAudioPlayerErrorCode: Int {
    case STKAudioPlayerErrorNone = 0,
    STKAudioPlayerErrorDataSource,
    STKAudioPlayerErrorStreamParseBytesFailed,
    STKAudioPlayerErrorAudioSystemError,
    STKAudioPlayerErrorCodecError,
    STKAudioPlayerErrorDataNotFound,
    STKAudioPlayerErrorOther = 0xffff
}

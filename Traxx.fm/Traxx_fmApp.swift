//
//  Traxx_fmApp.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 23/5/21.
//

import SwiftUI

@main
struct Traxx_fmApp: App {
    
    var player: AudioPlayer
    
    init() {
        player = AudioPlayer.shared
    }
    
    var body: some Scene {
        WindowGroup {
            AudioPlayerView()
        }
    }
}

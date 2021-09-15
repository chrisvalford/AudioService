//
//  AudioPlayerView.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 17/5/21.
//

import SwiftUI

struct AudioPlayerView: View {
    
    @ObservedObject var player = AudioPlayer.shared
    //(endpoint: "http://traxx001.ice.infomaniak.ch/traxx001-low.mp3")
    @ObservedObject var traxxChannels = TraxxChannels()
    
    var channels = [Channel]()
    
    init() {
        channels = traxxChannels.channels
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ZStack {
                    Rectangle()
                        .foregroundColor(.black)
                    VStack {
                        HStack(spacing: 2) {
                            ForEach(player.soundSamples, id: \.self) { level in
                                BarView(value: CGFloat(level * 350))
                            }
                        }
                    }.frame(width: geo.size.width, height: 280)
                    Image("AppLargeClear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                Text("Artist: \(player.artist)")
                Text("Track: \(player.title)")
                Button {
                    player.playOrPause()
                } label: {
                    player.isPlaying ? Image.pause : Image.play
                }
                .frame(width: 40)
                .font(.system(size: 45))
                List(channels, id: \.id) { channel in
                    Button {
                        player.currentStream = URL(string: channel.endpoint)!
                    } label: {
                        Text(channel.id)
                    }
                }
            }
        }
        
    }
}

struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        AudioPlayerView()
    }
}

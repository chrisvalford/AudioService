//
//  AudioPlayer.swift
//  MetadataTest
//
//  Created by Christopher Alford on 17/5/21.
//

import UIKit
import SwiftUI
import AudioToolbox

class AudioPlayer: NSObject, ObservableObject {
    
    static let shared = AudioPlayer(endpoint: "")
    
    @Published var artist: String = ""
    @Published var title: String = ""
    @Published public var soundSamples: [Float]
    @Published var status: String = ""
    @Published var isPlaying: Bool
    
    private let numberOfSamples: Int
    
    private var audioPlayer: STKAudioPlayer?
    private var timer: Timer?
    
    var currentStream: URL {
        didSet {
            self.play(endpoint: currentStream)
        }
    }
    
    init(endpoint: String) {
        self.numberOfSamples = 30
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentStream = URL(string: "http://traxx001.ice.infomaniak.ch/traxx001-low.mp3")!
        
        let frequencies = (Float32(50), Float32(100), Float32(200), Float32(400), Float32(800), Float32(1600), Float32(2600), Float32(16000),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0),Float32(0))
        
        let options = STKAudioPlayerOptions(flushQueueOnSeek: true,
                                            enableVolumeMixer: false,
                                            equalizerBandFrequencies: frequencies,
                                            readBufferSize: 0,
                                            bufferSizeInSeconds: 0,
                                            secondsRequiredToStartPlaying: 0,
                                            gracePeriodAfterSeekInSeconds: 0,
                                            secondsRequiredToStartPlayingAfterBufferUnderun: 0)
        
        audioPlayer = STKAudioPlayer(options: options)
        self.isPlaying = true
         
        super.init()
        setupTimer()
        updateControls()
        audioPlayer?.delegate = self
        audioPlayer?.meteringEnabled = true
        audioPlayer?.volume = 1
        //play(source: "")
    }
    
    func playOrPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.resume()
        }
        isPlaying.toggle()
    }
    
    func setupTimer() {
        timer = Timer(timeInterval: 0.001, target:self, selector: #selector(tick), userInfo:nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    @objc func tick() {
        status = audioPlayer?.state == STKAudioPlayerState.buffering ? "buffering" : " "
        let meterValue = scaledPower(power: 320 * (((audioPlayer?.averagePowerInDecibels(forChannel: 1))! + 60) / 60))
        self.soundSamples.append(meterValue)
        if self.soundSamples.count > self.numberOfSamples {
            self.soundSamples.remove(at: 0)
        }
    }
    
    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return 0.0
        }
        
        return power / 200
        
        
//        let minDb: Float = -80
//        
//        if power/500 < minDb {
//            return 0.0
//        } else if power/500 >= 1.0 {
//            return 1.0
//        } else {
//            return (abs(minDb) - abs(power/500)) / abs(minDb)
//        }
    }
    
    func play(endpoint: URL) {
        let dataSource: STKDataSource = STKAudioPlayer.dataSource(from: currentStream)
        audioPlayer?.setDataSource(dataSource, withQueueItemId: SampleQueueId(url: currentStream, count: 0))
        artist = ""
        title = ""
    }
    
    func updateControls() {
//        if audioPlayer == nil {
//            playButton.setTitle(" ", for: .normal)
//        } else if (audioPlayer?.state == STKAudioPlayerState.paused) {
//            playButton.setTitle("Resume", for: .normal)
//        } else if (audioPlayer?.state == STKAudioPlayerState.playing) {
//            playButton.setTitle("Pause", for: .normal)
//        } else {
//            playButton.setTitle(" ", for: .normal)
//        }
        tick()
    }
    
}

extension AudioPlayer: STKAudioPlayerDelegate {
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        updateControls()
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        updateControls()
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        let queueId = queueItemId as! SampleQueueId
        
        print("Started: %@", queueId.url.description)
        
        updateControls()
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        updateControls()
        
        // This queues on the currently playing track to be buffered and played immediately after (gapless)
        
//        if repeatSwitch.isOn {
//            let queueId = queueItemId as! SampleQueueId
//
//            print("Requeuing: %@", queueId.url.description)
//
//            audioPlayer.queue(STKAudioPlayer.dataSource(from: queueId.url),
//                              withQueueItemId: SampleQueueId(url: queueId.url, count: queueId.count + 1))
//        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer,
                     didFinishPlayingQueueItemId queueItemId: NSObject,
                     with stopReason: STKAudioPlayerStopReason,
                     andProgress progress: Double,
                     andDuration duration: Double) {
        updateControls()
        
        let queueId = queueItemId as! SampleQueueId
        
        print("Finished: \(queueId.url.description)")
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, logInfo line: String) {
        print("\(line)")
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didReadStreamMetadata dictionary: [AnyHashable : Any]) {
        DispatchQueue.main.async {
            if let meta = dictionary["StreamTitle"] as? String {
                print(meta)
                let metaComponents = meta.components(separatedBy: " - ")
                if metaComponents.count > 1 {
                    self.artist = metaComponents[0]
                    self.title = metaComponents[1]
                } else {
                    self.artist = meta
                }
            } else {
                self.artist = ""
                self.title = ""
            }
        }
    }
}



//
//  AudioRecorder.swift
//  AudioFill-iOS
//
//  Created by Eldad Ohana on 22/05/2024.
//

import Foundation
import AVFoundation

class AudioRecorderWithEngine: NSObject {
    
    let bufferSize: AVAudioFrameCount = 1024
    var engine: AVAudioEngine = .init()
    var currentRecorded: [Double] = .init()
    var audioPlayer: AVAudioPlayer?
    
    func startRecording() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task(priority: .userInitiated) {
                do {
                    self.currentRecorded = .init()
                    let format = self.engine.inputNode.inputFormat(forBus: 0)
                    self.engine.inputNode.installTap(onBus: 0,
                                                     bufferSize: self.bufferSize,
                                                     format: format) { (buffer, time) -> Void in
                        self.currentRecorded = self.currentRecorded.append(buffer: buffer)
                    }
                    try self.engine.start()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stopRecording() {
        Task {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
    }
    
    func getCurrentRecording() -> [Double]? {
        return self.currentRecorded
    }
}

extension Array where Element == Double {
    func append(buffer: AVAudioPCMBuffer) -> [Double] {
        guard let floatChannelData = buffer.floatChannelData else {
            print("Could not get float channel data")
            return []
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = 1
        var audioData: [Double] = []
        
        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let sample = floatChannelData[channel][frame]
                audioData.append(Double(sample))
            }
        }
        return self + audioData
    }
}

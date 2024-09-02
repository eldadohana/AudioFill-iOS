//
//  RecordingViewModel.swift
//  AudioFill-iOS
//
//  Created by Eldad Ohana on 12/04/2024.
//

import Foundation

class RecordingViewModel: ObservableObject {
    
    enum ViewState {
        case idle
        case recording
        case full
    }
    
    @Published var isRecording: Bool = false
    @Published var currentPercentage: Int = 0
    @Published var viewState: ViewState = .idle
    
    private let audioRecorder: AudioRecorderWithEngine = .init()
    private var timer: Timer?
    private let audioML: AudioML = .init()
    private let fullStateThreshold = 85
    
    func recordingButtonTap() {
        if isRecording {
            stopRecording()
            viewState = .idle
        }
        else {
            startRecording()
            viewState = .recording
        }
        isRecording = !isRecording
    }
}

private extension RecordingViewModel {
    
    func startRecording() {
        self.currentPercentage = 0
        audioRecorder.startRecording()
        makePredictionEvery(seconds: 3)
    }
    
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder.stopRecording()
    }
    
    func predictFullState() async -> Float? {
        guard let rawAudio = audioRecorder.getCurrentRecording() else {
            return nil
        }
        print("Pulling raw audio of size: \(rawAudio.count)")
        guard let inputData = AudioUtils.rawAudioToDataUsingFloatArray(rawAudio) else {
            print("Couldn't convert raw audio to data")
            return nil
        }
        return try? await self.audioML.predictionForAudioBuffer(inputData)
    }
    
    func makePredictionEvery(seconds: TimeInterval) {
        self.timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { _ in
            Task {
                guard let prediction = await self.predictFullState() else {
                    return
                }
                if !prediction.isNaN {
                    DispatchQueue.main.async {
//                        self.currentPercentage = Int(prediction * 100)
                        self.currentPercentage += 10
                        // Detecting full state
                        if self.currentPercentage >= self.fullStateThreshold {
                            self.reachedToFullState()
                        }
                    }
                }
            }
        }
    }
    
    func reachedToFullState() {
        stopRecording()
        isRecording = false
        viewState = .full
    }
}

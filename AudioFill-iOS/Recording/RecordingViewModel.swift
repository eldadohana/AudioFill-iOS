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
        case error(RecordingViewModelError)
    }
    
    enum RecordingViewModelError: Error {
        case audioRecordingFailure
        case audioProcessingFailure
        case predictionFailure
        case unknownError
    }
    
    @Published var isRecording: Bool = false
    @Published var currentPercentage: Int = 0
    @Published var viewState: ViewState = .idle
    
    private let audioRecorder: AudioRecorderWithEngine = .init()
    private let audioML: AudioML = .init()
    private let fullStateThreshold = 85
    private var predictionTask: Task<Void, Never>?

    
    func recordingButtonTap() {
        if isRecording {
            stopProcess()
            updateUIState(to: .idle)
        }
        else {
            startProcess()
            updateUIState(to: .recording)
        }
    }
}

private extension RecordingViewModel {
    
    func startProcess() {
        Task {
            await MainActor.run {
                currentPercentage = 0
                isRecording = true
            }
            do {
                try await audioRecorder.startRecording()
                makePrediction(every: 3)
            } catch {
                handleError(error)
            }
        }
    }
    
    func stopProcess() {
        stopPredictions()
        audioRecorder.stopRecording()
        Task { @MainActor in
            isRecording = false
        }
    }
    
    func makePrediction(every seconds: TimeInterval) {
        predictionTask = Task {
            while !Task.isCancelled {
                do {
                    let prediction = try await self.predictState()
                    if !prediction.isNaN {
                        let percentage = Int(prediction * 100)
                        await MainActor.run {
                            self.currentPercentage = percentage
                            if self.currentPercentage >= self.fullStateThreshold {
                                self.reachedToFullState()
                            }
                        }
                    }
                    try? await Task.sleep(for: .seconds(seconds))
                }
                catch {
                    handleError(error)
                }
            }
        }
    }
    
    func stopPredictions() {
        predictionTask?.cancel()
        predictionTask = nil
    }
    
    func predictState() async throws -> Float {
        guard let rawAudio = audioRecorder.getCurrentRecording() else {
            throw RecordingViewModelError.audioRecordingFailure
        }
        guard let inputData = AudioUtils.rawAudioToDataUsingFloatArray(rawAudio) else {
            throw RecordingViewModelError.audioProcessingFailure
        }
        do {
            return try await self.audioML.predictionForAudioBuffer(inputData)
        } catch {
            throw RecordingViewModelError.predictionFailure
        }
    }
    
    func reachedToFullState() {
        stopProcess()
        updateUIState(to: .full)
    }
    
    func handleError(_ error: Error) {
        stopProcess()
        let recordingError = (error as? RecordingViewModelError) ?? .unknownError
        updateUIState(to: .error(recordingError))
    }
        
    func updateUIState(to state: ViewState) {
        Task { @MainActor in
            self.viewState = state
        }
    }
}

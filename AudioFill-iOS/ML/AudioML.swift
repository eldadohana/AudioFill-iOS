//
//  AudioML.swift
//  AudioFill-iOS
//
//  Created by Eldad Ohana on 29/05/2024.
//

import Foundation
import CoreML
import TensorFlowLite

enum AudioMLError: Error {
    case modelInitializationFailure
    case predictionFailure
}

class AudioML {
    private let modelName = "cnn_regression_v5"
    private var interpreter: Interpreter?
    
    init() {
        Task(priority: .userInitiated) {
            self.interpreter = self.setupInterpreter()
        }
    }
    
    func predictionForAudioBuffer(_ buffer: Data) async throws -> Float {
        return try await Task { () -> Float in
            do {
                guard let interpreter = self.interpreter else {
                    throw AudioMLError.modelInitializationFailure
                }
                try interpreter.copy(buffer, toInputAt: 0)
                try interpreter.invoke()
                
                let outputTensor = try interpreter.output(at: 0)
                let outputData = outputTensor.data
                
                let prediction: Float = outputData.withUnsafeBytes { pointer in
                    pointer.load(as: Float.self)
                }
                return prediction
            } catch {
                throw AudioMLError.predictionFailure
            }
        }.result.get()
    }
}

private extension AudioML {
    func setupInterpreter() -> Interpreter? {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            return nil
        }
        
        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
            return interpreter
        } catch {
            return nil
        }
    }
}

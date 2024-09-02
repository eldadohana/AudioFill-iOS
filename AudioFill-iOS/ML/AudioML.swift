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
    case predictionFailure
}

class AudioML {
    private let modelName = "cnn_regression_v5"
    private let queue = DispatchQueue(label: "audioML", qos: .userInteractive)
    private var interpreter: Interpreter!
    
    init() {
        queue.async {
            self.interpreter = self.setupInterpreter()
        }
    }
    
    func predictionForAudioBuffer(_ buffer: Data) async throws -> Float {
        return try await Task { () -> Float in
            do {
                try interpreter.copy(buffer, toInputAt: 0)
                try interpreter.invoke()
                
                let outputTensor = try interpreter.output(at: 0)
                let outputData = outputTensor.data
                
                let prediction: Float = outputData.withUnsafeBytes { pointer in
                    pointer.load(as: Float.self)
                }
                print("Prediction: \(prediction)")
                return prediction
            } catch {
                print("Error: \(error)")
                throw AudioMLError.predictionFailure
            }
        }.result.get()
    }
}

private extension AudioML {
    func setupInterpreter() -> Interpreter? {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            fatalError("Model not found")
        }
        
        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
            return interpreter
        } catch let error {
            print("Failed to create interpreter: \(error)")
        }
        return nil
    }
}

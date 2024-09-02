//
//  AudioUtils.swift
//  AudioFill-iOS
//
//  Created by Eldad Ohana on 29/05/2024.
//

import Foundation
import CoreML
import AVFoundation
import RosaKit

class AudioUtils {
    
    static func rawAudioToDataUsingFloatArray(_ rawAudio: [Double]) -> Data? {
        let size = 128
        let melSpectrogram = rawAudio.melspectrogram()

        guard let scaledMel = MLUtils.resizeMelSpectrogram(melSpectrogram, newSize: size) else { return nil }

        return scaledMel.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}

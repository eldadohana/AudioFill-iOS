//
//  MLUtils.swift
//  AudioFill-iOS
//
//  Created by Eldad Ohana on 12/04/2024.
//

import Foundation
import CoreML
import AVFoundation
import SwiftUI

struct MLUtils {
    
    static func resizeMelSpectrogram(_ input: [[Double]], newSize: Int) -> [Float]? {
        let inputRows = input.count
        let inputCols = input[0].count
        let outputRows = newSize
        let outputCols = newSize
        
        guard inputRows > 0 && inputCols > 0 && outputRows > 0 && outputCols > 0 else {
            return nil
        }
        
        var output: [Float] = .init()
        
        let rowRatio = Float(inputRows) / Float(outputRows)
        let colRatio = Float(inputCols) / Float(outputCols)
        
        for i in 0..<outputRows {
            for j in 0..<outputCols {
                let sourceRow = Int(Float(i) * rowRatio)
                let sourceCol = Int(Float(j) * colRatio)
                
                let sourceValue = input[min(sourceRow, inputRows - 1)][min(sourceCol, inputCols - 1)]
                output.append(Float(sourceValue))
            }
        }
        
        return output
    }
}

//
//  RecordingView.swift
//  AudioFill-iOS
//
//  Created by Eldad Ohana on 29/05/2024.
//

import SwiftUI

struct RecordingView: View {
    @StateObject var viewModel: RecordingViewModel = .init()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RecordingBackgroundView()
            switch viewModel.viewState {
            case .idle:
                EmptyView()
            case .recording:
                RecordingPercentView(currentPercentage: $viewModel.currentPercentage)
                    .padding(.bottom, 500)
            case .full:
                RecordingFullView()
                    .padding(.bottom, 600)
            case .error(let error):
                RecordingErrorView(error: error)
                    .padding(.bottom, 600)
            }
            RecordingActionButtonView(isRecording: $viewModel.isRecording) {
                viewModel.recordingButtonTap()
            }
        }
    }
}

#Preview("Idle") {
    RecordingView()
}

#Preview("Recording") {
    var viewModel: RecordingViewModel = .init()
    viewModel.viewState = .recording
    viewModel.currentPercentage = 35
    return RecordingView(viewModel: viewModel)
}

#Preview("Full") {
    var viewModel: RecordingViewModel = .init()
    viewModel.viewState = .full
    return RecordingView(viewModel: viewModel)
}

#Preview("Error") {
    var viewModel: RecordingViewModel = .init()
    viewModel.viewState = .error(.audioProcessingFailure)
    return RecordingView(viewModel: viewModel)
}

struct RecordingFullView: View {
    var body: some View {
        RecordingStateView(text: .constant("Full"), 
                           background: .green)
    }
}

struct RecordingPercentView: View {
    @Binding var currentPercentage: Int
    
    var body: some View {
        RecordingStateView(text: .constant("\(currentPercentage)%"), 
                           background: .gray)
    }
}

struct RecordingStateView: View {
    @Binding var text: String
    var background: Color
    
    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.largeTitle)
            .padding()
            .background(background)
            .mask {
                LinearGradient(gradient:
                                Gradient(colors: [Color.black,
                                                  Color.black,
                                                  Color.black,
                                                  Color.black.opacity(0)]),
                               startPoint: .top, endPoint: .bottom)
            }
            .clipShape(.capsule)
    }
}

struct RecordingBackgroundView: View {
    var body: some View {
        Image("glassOfWater")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
            .padding(.leading, -20)
    }
}

struct RecordingActionButtonView: View {
    @Binding var isRecording: Bool
    @State var recordingButtonTap: () -> Void
    
    var body: some View {
        Button(action: {
            recordingButtonTap()
        }, label: {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.white)
                    .frame(width: 80, height: 80)
                if isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                }
            }
        })
        .padding()
    }
}

struct RecordingErrorView: View {
    let error: RecordingViewModel.RecordingViewModelError
    
    var body: some View {
        RecordingStateView(text: .constant(errorMessage), 
                           background: .red)
    }
    
    private var errorMessage: String {
        switch error {
        case .audioRecordingFailure:
            return "Recording Failed"
        case .audioProcessingFailure:
            return "Audio Processing Failure"
        case .predictionFailure:
            return "Prediction Error"
        case .unknownError:
            return "Unknown Error"
        }
    }
}

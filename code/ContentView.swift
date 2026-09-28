import SwiftUI
import AudioToolbox
import UIKit

enum TimerMode: String, CaseIterable {
    case study = "study"
    case breakTime = "break"
    
    var duration: Int {
        switch self {
        case .study:
            return 25 * 60
        case .breakTime:
            return 5 * 60
        }
    }
}

struct ContentView: View {
    @State private var selectedMode: TimerMode = .study
    @State private var timeRemaining: Int = TimerMode.study.duration
    @State private var isRunning: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var minutes: Int {
        timeRemaining / 60
    }
    
    var seconds: Int {
        timeRemaining % 60
    }
    
    var body: some View {
        ZStack {
            // Main content centered vertically and horizontally
            VStack {
                Spacer()
                
                // Center Stack: Timer, Controls, and Modes
                VStack(spacing: 22) {
                    // Countdown display
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    // Controls: Play/Pause and Reset loop icon
                    HStack(spacing: 28) {
                        Button {
                            isRunning.toggle()
                        } label: {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            resetTimer()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Modes list
                    VStack(spacing: 8) {
                        ForEach(TimerMode.allCases, id: \.self) { mode in
                            let isSelected = selectedMode == mode
                            
                            Button {
                                switchMode(to: mode)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(mode.rawValue)
                                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular, design: .rounded))
                                        .italic(!isSelected)
                                    
                                    if isSelected {
                                        Text("•")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                                .foregroundColor(isSelected ? .primary : .secondary.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .top) {
            Text("pomimi")
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 8)
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                isRunning = false
                triggerTimerCompletionFeedback()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func switchMode(to mode: TimerMode) {
        selectedMode = mode
        resetTimer()
    }
    
    private func resetTimer() {
        isRunning = false
        timeRemaining = selectedMode.duration
    }
    
    private func triggerTimerCompletionFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        AudioServicesPlaySystemSound(1005)
    }
}
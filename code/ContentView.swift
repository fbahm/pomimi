import SwiftUI
import AudioToolbox
import UIKit

enum TimerMode: String, CaseIterable {
    case work = "Work"
    case breakTime = "Break"
    
    var duration: Int {
        switch self {
        case .work:
            return 25 * 60
        case .breakTime:
            return 5 * 60
        }
    }
}

struct ContentView: View {
    @State private var selectedMode: TimerMode = .work
    @State private var timeRemaining: Int = TimerMode.work.duration
    @State private var isRunning: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Custom binding that triggers switchMode automatically whenever a tab is tapped
    private var modeBinding: Binding<TimerMode> {
        Binding(
            get: { selectedMode },
            set: { newMode in
                selectedMode = newMode
                switchMode(to: newMode)
            }
        )
    }
    
    var minutes: Int {
        timeRemaining / 60
    }
    
    var seconds: Int {
        timeRemaining % 60
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Pomimi")
                .font(.largeTitle)
                .bold()
            
            // Picker binds directly to modeBinding
            Picker("Mode", selection: modeBinding) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 32)
            
            // Timer Display
            Text(String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
            
            // Controls
            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    resetTimer()
                }
                .buttonStyle(.bordered)
            }
            .font(.title2)
        }
        .padding()
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
        isRunning = false
        timeRemaining = mode.duration
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

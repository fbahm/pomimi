import SwiftUI

struct ContentView: View {
    @State private var timeRemaining: Int = 1500
    @State private var isRunning: Bool = false
    
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
            
            Text(String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
            
            Button(isRunning ? "Pause" : "Start") {
                isRunning.toggle()
            }
            .font(.title2)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}


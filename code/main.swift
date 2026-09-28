import SwiftUI // graphical interface

struct ContentView: View {
    @State private var timeRemaining: Int = 1500
    @State private var isRunning: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Pomimi")
            .font(.largeTitle)
            .bold()

            Text("\\(timeRemaining / 60):\\(String(format: "%02d", timeRemaining % 60))")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                
            Button (isRunning ? "Pause" : "Start"){
                isRunning.toggle()
            }
            .font(.title2)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
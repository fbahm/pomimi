import SwiftUI

struct ContentView: View {
    @State private var timeRemaining: Int = 1500
    @State private var isRunning: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            
            HStack(spacing: 16){
                Button(isRunning ? "Pause" : "Start"){
                    isRunning.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset"){
                    isRunning = false
                    timeRemaining = 1500
                }
                .buttonStyle(.bordered)
            }
            .font(.title2)
        }
        .padding()
        .onReceive(timer){_ in 
            guard isRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                isRunning = false
            }
        }
    }
}


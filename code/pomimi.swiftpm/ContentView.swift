import SwiftUI
import AudioToolbox
import UIKit
import UserNotifications

// MARK: - Color Palette
extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum Palette {
    static let red    = Color(hex: 0xD62839)  // accents: play button, selected dot, save
    static let peach  = Color(hex: 0xFFDBB5)  // fills: tag pill, text fields, preview card
    static let cream  = Color(hex: 0xFFF4E6)  // backgrounds
    static let pink   = Color(hex: 0xE87A86)  // secondary: unselected items, reset, trash
    static let maroon = Color(hex: 0x5C161D)  // primary text
}

private extension View {
    func paletteField() -> some View {
        self.padding(10)
            .background(Palette.peach)
            .cornerRadius(10)
            .foregroundColor(Palette.maroon)
            .tint(Palette.red)
    }
}

// MARK: - Models
struct PomodoroTag: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var workMinutes: Int
    var breakMinutes: Int
}

enum TimerMode: String, CaseIterable {
    case study = "study"
    case breakTime = "break"
}

private let initialDefaultTag = PomodoroTag(name: "default", workMinutes: 25, breakMinutes: 5)

// MARK: - Main View
struct ContentView: View {
    
    @Environment(\.scenePhase) var scenePhase
    
    @State private var tags: [PomodoroTag] = [initialDefaultTag]
    @State private var selectedTag: PomodoroTag = initialDefaultTag
    
    // Timer state
    @State private var selectedMode: TimerMode = .study
    @State private var timeRemaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    
    // Background tracking state
    @State private var targetEndDate: Date?
    
    // Presentation states
    @State private var showTagSelector: Bool = false
    @State private var showAddTagSheet: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var minutes: Int {
        timeRemaining / 60
    }
    
    var seconds: Int {
        timeRemaining % 60
    }
    
    var currentModeDuration: Int {
        switch selectedMode {
        case .study:
            return selectedTag.workMinutes * 60
        case .breakTime:
            return selectedTag.breakMinutes * 60
        }
    }
    
    var body: some View {
        VStack {
            // Header pinned cleanly below dynamic island / notch
            Text("pomimi")
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundColor(Palette.maroon)
                .padding(.top, 16)
            
            Spacer()
            
            // Center Cluster
            VStack(spacing: 18) {
                
                // Tag Selector Pill Button
                Button {
                    showTagSelector = true
                } label: {
                    Text(selectedTag.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.maroon)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Palette.peach))
                }
                .buttonStyle(.plain)
                
                // Countdown display
                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Palette.maroon)
                
                // Play/Pause & Reset Controls
                HStack(spacing: 32) {
                    Button {
                        isRunning.toggle()
                    } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Palette.red)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        resetTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Palette.pink)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
                
                // Study / Break Mode List
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
                                    .foregroundColor(isSelected ? Palette.maroon : Palette.pink)
                                
                                if isSelected {
                                    Text("•")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Palette.red)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 10)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.cream.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onReceive(timer) { _ in
            guard isRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                finishTimer()
            }
        }
        .onAppear {
            requestNotificationPermission()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                appMovedToBackground()
            } else if newPhase == .active {
                appMovedToForeground()
            }
        }
        // Tag selector sheet
        .sheet(isPresented: $showTagSelector) {
            TagSelectorSheet(
                tags: tags,
                selectedID: selectedTag.id,
                onSelectTag: { tag in
                    selectedTag = tag
                    resetTimer()
                    showTagSelector = false
                },
                onDeleteTag: deleteTag,
                onAddNewTagTapped: {
                    showTagSelector = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAddTagSheet = true
                    }
                }
            )
            .presentationDetents([.medium])
        }
        // Add tag input sheet
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet { newTag in
                tags.append(newTag)
                selectedTag = newTag
                resetTimer()
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Helper Methods
    private func switchMode(to mode: TimerMode) {
        selectedMode = mode
        resetTimer()
    }
    
    private func resetTimer() {
        isRunning = false
        timeRemaining = currentModeDuration
    }
    
    private func deleteTag(_ tag: PomodoroTag) {
        guard tag.name != "default" else { return }
        
        tags.removeAll { $0.id == tag.id }
        
        if selectedTag.id == tag.id {
            if let defaultTag = tags.first(where: { $0.name == "default" }) {
                selectedTag = defaultTag
            }
            resetTimer()
        }
    }
    
    private func finishTimer() {
        isRunning = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1005)
    }
    
    // MARK: - Background Processing Methods
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleTimerNotification(durationInSeconds: TimeInterval, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: durationInSeconds, repeats: false)
        let request = UNNotificationRequest(identifier: "pomimiTimerComplete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func appMovedToBackground() {
        guard isRunning else { return }
        
        let interval = TimeInterval(timeRemaining)
        targetEndDate = Date().addingTimeInterval(interval)
        
        let isStudying = selectedMode == .study
        scheduleTimerNotification(
            durationInSeconds: interval,
            title: isStudying ? "Pomodoro Finished!" : "Break Over!",
            body: isStudying ? "Take a break :)" : "Time to get back to work :)"
        )
    }
    
    private func appMovedToForeground() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pomimiTimerComplete"])
        
        guard isRunning, let end = targetEndDate else { return }
        targetEndDate = nil
        timeRemaining = max(0, Int(end.timeIntervalSinceNow))
        if timeRemaining == 0 { finishTimer() }
    }
}

// MARK: - Tag Selector Pop-Up Sheet
struct TagSelectorSheet: View {
    let tags: [PomodoroTag]
    let selectedID: UUID
    let onSelectTag: (PomodoroTag) -> Void
    let onDeleteTag: (PomodoroTag) -> Void
    let onAddNewTagTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("tags")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .underline()
                .foregroundColor(Palette.maroon)
                .padding(.top, 24)
            
            VStack(spacing: 12) {
                ForEach(tags) { tag in
                    let isSelected = selectedID == tag.id
                    let isDefault = tag.name == "default"
                    
                    HStack(spacing: 10) {
                        Button {
                            onSelectTag(tag)
                        } label: {
                            HStack(spacing: 6) {
                                Text(tag.name)
                                    .font(.system(size: 22, weight: isSelected ? .bold : .regular, design: .rounded))
                                    .italic(!isSelected)
                                    .foregroundColor(isSelected ? Palette.maroon : Palette.pink)
                                
                                if isSelected {
                                    Text("•")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Palette.red)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if !isDefault {
                            Button {
                                onDeleteTag(tag)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(Palette.pink)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Button {
                    onAddNewTagTapped()
                } label: {
                    Text("add tag :)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .italic()
                        .foregroundColor(Palette.red)
                        .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(Palette.cream.ignoresSafeArea())
    }
}

// MARK: - Add Tag Sheet (Custom Header & Keyboard Scroll-Safe)
struct AddTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var workMinutesText: String = "25"
    @State private var breakMinutesText: String = "5"
    
    let onSave: (PomodoroTag) -> Void
    
    var workMinutes: Int {
        Int(workMinutesText) ?? 25
    }
    
    var breakMinutes: Int {
        Int(breakMinutesText) ?? 5
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && workMinutes > 0 && breakMinutes > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean custom top bar without overlapping navigation titles
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Palette.maroon.opacity(0.6))
                
                Spacer()
                
                Text("New Tag")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.maroon)
                
                Spacer()
                
                Button("Save") {
                    let newTag = PomodoroTag(
                        name: name.trimmingCharacters(in: .whitespaces),
                        workMinutes: workMinutes,
                        breakMinutes: breakMinutes
                    )
                    onSave(newTag)
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(isValid ? Palette.red : Palette.pink.opacity(0.5))
                .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 20) {
                    TextField("tag name (e.g. coding)", text: $name)
                        .paletteField()
                        .padding(.top, 8)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("work (mins)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Palette.maroon.opacity(0.7))
                            TextField("25", text: $workMinutesText)
                                .keyboardType(.numberPad)
                                .paletteField()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("break (mins)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Palette.maroon.opacity(0.7))
                            TextField("5", text: $breakMinutesText)
                                .keyboardType(.numberPad)
                                .paletteField()
                        }
                    }
                    
                    // Live preview card
                    VStack(spacing: 6) {
                        Text("preview")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Palette.maroon.opacity(0.7))
                        
                        Text("\(name.isEmpty ? "untitled" : name) • \(workMinutes)m work / \(breakMinutes)m break")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Palette.maroon)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Palette.peach)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Palette.cream.ignoresSafeArea())
    }
}

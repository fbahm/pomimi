import SwiftUI
import AudioToolbox
import UIKit

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
    @State private var tags: [PomodoroTag] = [initialDefaultTag]
    @State private var selectedTag: PomodoroTag = initialDefaultTag
    
    // Timer state
    @State private var selectedMode: TimerMode = .study
    @State private var timeRemaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    
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
        ZStack {
            // Background to guarantee full-screen canvas in both light and dark mode
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Main content
            VStack {
                // Header pinned cleanly below the dynamic island / status bar
                Text("pomimi")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
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
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Countdown display
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    // Play/Pause & Reset Controls
                    HStack(spacing: 32) {
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
                Spacer() // Keeps the visual weight slightly balanced relative to home indicator
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .sheet(isPresented: $showTagSelector) {
            TagSelectorSheet(
                tags: tags,
                selectedTag: $selectedTag,
                onSelectTag: { tag in
                    selectedTag = tag
                    resetTimer()
                    showTagSelector = false
                },
                onDeleteTag: { tagToDelete in
                    deleteTag(tagToDelete)
                },
                onAddNewTagTapped: {
                    showTagSelector = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAddTagSheet = true
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet { newTag in
                tags.append(newTag)
                selectedTag = newTag
                resetTimer()
            }
            .presentationDetents([.medium])
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
    
    private func triggerTimerCompletionFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        AudioServicesPlaySystemSound(1005)
    }
}

// MARK: - Tag Selector Pop-Up
struct TagSelectorSheet: View {
    let tags: [PomodoroTag]
    @Binding var selectedTag: PomodoroTag
    let onSelectTag: (PomodoroTag) -> Void
    let onDeleteTag: (PomodoroTag) -> Void
    let onAddNewTagTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("tags")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .underline()
                .padding(.top, 24)
            
            VStack(spacing: 12) {
                ForEach(tags) { tag in
                    let isSelected = selectedTag.id == tag.id
                    let isDefault = tag.name == "default"
                    
                    HStack(spacing: 10) {
                        Button {
                            onSelectTag(tag)
                        } label: {
                            HStack(spacing: 6) {
                                Text(tag.name)
                                    .font(.system(size: 22, weight: isSelected ? .bold : .regular, design: .rounded))
                                    .italic(!isSelected)
                                
                                if isSelected {
                                    Text("•")
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }
                            .foregroundColor(isSelected ? .primary : .secondary.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                        
                        if !isDefault {
                            Button {
                                onDeleteTag(tag)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary.opacity(0.4))
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
                        .foregroundColor(.secondary.opacity(0.65))
                        .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

// MARK: - Add Tag Sheet
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
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    TextField("tag name (e.g. coding)", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("work (mins)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            TextField("25", text: $workMinutesText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("break (mins)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            TextField("5", text: $breakMinutesText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(.top, 16)
                
                VStack(spacing: 6) {
                    Text("preview")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("\(name.isEmpty ? "untitled" : name) • \(workMinutes)m work / \(breakMinutes)m break")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newTag = PomodoroTag(
                            name: name.trimmingCharacters(in: .whitespaces),
                            workMinutes: workMinutes,
                            breakMinutes: breakMinutes
                        )
                        onSave(newTag)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

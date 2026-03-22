// NLMoodInputView.swift — "How are you feeling?" input bar with voice support.
// Fires on-device fallback immediately for instant response, then backend for better suggestions.
// Both paths are non-exclusive — the fallback picks music now, backend refines suggestions after.
import SwiftUI
import FontAwesome

struct NLMoodInputView: View {
    @EnvironmentObject private var musicController: MusicController
    @StateObject private var speech = SpeechManager()
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var onMoodSelected: (EnhancedMood) -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Input row
            HStack(spacing: 10) {
                TextField("How are you feeling?", text: $inputText)
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onSubmit { submitIfNeeded() }

                // Voice toggle
                Button(action: toggleVoice) {
                    Text(speech.isListening ? Icons.close : Icons.mic)
                        .font(Font.fontAwesome(ofSize: 18, style: .solid))
                        .foregroundColor(speech.isListening ? .red : .gray)
                }

                // Submit — only visible when there's text
                if !inputText.isEmpty {
                    Button(action: submitIfNeeded) {
                        Text(Icons.search)
                            .font(Font.fontAwesome(ofSize: 18, style: .solid))
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Backend mood suggestions — shown after classify_mood responds
            if !musicController.moodSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(musicController.moodSuggestions, id: \.mood) { suggestion in
                            MoodSuggestionRow(suggestion: suggestion) {
                                if let match = enhancedMoods.first(where: {
                                    $0.title.lowercased() == suggestion.mood.lowercased()
                                }) {
                                    onMoodSelected(match)
                                    inputText = ""
                                    musicController.moodSuggestions = []
                                    isFocused = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .onChange(of: speech.transcript) { _, new in
            if !new.isEmpty { inputText = new }
        }
    }

    private func submitIfNeeded() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // On-device instant pick — user hears music before backend wakes up
        if let fallback = MoodFallbackClassifier.classify(trimmed),
           let match = enhancedMoods.first(where: { $0.title == fallback }) {
            onMoodSelected(match)
        }
        // Backend call for richer suggestions (async — populates moodSuggestions)
        Task { await musicController.generate(forText: trimmed) }
        isFocused = false
    }

    private func toggleVoice() {
        speech.isListening ? speech.stopListening() : speech.startListening()
    }
}

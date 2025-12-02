//
//  FeedbackView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackType: FeedbackType = .general
    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var error: String?

    private let authService = AuthService.shared
    private let feedbackService = FeedbackService.shared

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }
            } header: {
                Text("Feedback Type")
            }

            Section {
                TextField("Brief summary", text: $title)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Text("Title")
            }

            Section {
                TextEditor(text: $description)
                    .frame(minHeight: 150)
            } header: {
                Text("Description")
            } footer: {
                Text("Please provide as much detail as possible to help us understand your feedback.")
            }

            Section {
                Button {
                    submitFeedback()
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Feedback")
                        }
                        Spacer()
                    }
                }
                .disabled(title.isEmpty || description.isEmpty || isSubmitting)
            }
        }
        .navigationTitle("Send Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Feedback Submitted", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your feedback! We'll review it and take action as needed.")
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }

    private func submitFeedback() {
        guard let user = authService.currentUser else { return }

        isSubmitting = true
        error = nil

        Task {
            do {
                _ = try await feedbackService.submitFeedback(
                    userId: user.id,
                    householdId: user.householdId,
                    type: feedbackType,
                    title: title,
                    description: description,
                    screenName: "FeedbackView"
                )
                showSuccess = true
            } catch {
                self.error = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - Feedback History View

struct FeedbackHistoryView: View {
    @State private var feedbackItems: [Feedback] = []
    @State private var isLoading = false
    @State private var error: String?

    private let authService = AuthService.shared
    private let feedbackService = FeedbackService.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading feedback...")
            } else if feedbackItems.isEmpty {
                ContentUnavailableView(
                    "No Feedback Yet",
                    systemImage: "bubble.left",
                    description: Text("Feedback you submit will appear here")
                )
            } else {
                List(feedbackItems) { item in
                    FeedbackRowView(feedback: item)
                }
            }
        }
        .navigationTitle("My Feedback")
        .task {
            await loadFeedback()
        }
        .refreshable {
            await loadFeedback()
        }
    }

    private func loadFeedback() async {
        guard let userId = authService.currentUser?.id else { return }

        isLoading = feedbackItems.isEmpty
        do {
            feedbackItems = try await feedbackService.fetchUserFeedback(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct FeedbackRowView: View {
    let feedback: Feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: feedback.type.iconName)
                    .foregroundStyle(colorForType)

                Text(feedback.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(feedback.status.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForStatus.opacity(0.2))
                    .foregroundStyle(colorForStatus)
                    .clipShape(Capsule())
            }

            Text(feedback.title)
                .font(.headline)

            Text(feedback.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(feedback.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var colorForType: Color {
        switch feedback.type {
        case .bug: return .red
        case .feature: return .blue
        case .general: return .gray
        case .praise: return .pink
        }
    }

    private var colorForStatus: Color {
        switch feedback.status {
        case .new: return .blue
        case .reviewed: return .orange
        case .inProgress: return .purple
        case .resolved: return .green
        case .wontFix: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}

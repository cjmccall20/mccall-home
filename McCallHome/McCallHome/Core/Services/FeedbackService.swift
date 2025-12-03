//
//  FeedbackService.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import Foundation
import UIKit
import Supabase

class FeedbackService {
    static let shared = FeedbackService()

    private init() {}

    // MARK: - Submit Feedback

    func submitFeedback(
        userId: UUID,
        householdId: UUID,
        type: FeedbackType,
        title: String,
        description: String,
        screenName: String? = nil
    ) async throws -> Feedback {
        let feedback = Feedback(
            userId: userId,
            householdId: householdId,
            type: type,
            title: title,
            description: description,
            appVersion: appVersion,
            iosVersion: iosVersion,
            deviceModel: deviceModel,
            screenName: screenName
        )

        // In dev mode, skip database save (foreign key constraint)
        // Just send the email notification
        if !Config.skipAuthForDevelopment {
            // Save to database only when not in dev mode
            try await supabase
                .from("feedback")
                .insert(feedback)
                .execute()
        }

        // Send email notification (works in both modes)
        await sendFeedbackEmail(feedback: feedback)

        return feedback
    }

    // MARK: - Send Feedback Email

    private func sendFeedbackEmail(feedback: Feedback) async {
        // Get user info for the email
        let userName = AuthService.shared.currentUser?.name ?? "Unknown User"
        let userEmail = AuthService.shared.currentUser?.email ?? "unknown@example.com"

        struct FeedbackEmailPayload: Encodable {
            let type: String
            let title: String
            let description: String
            let userName: String
            let userEmail: String
            let appVersion: String
            let iosVersion: String
            let deviceModel: String
        }

        let payload = FeedbackEmailPayload(
            type: feedback.type.rawValue,
            title: feedback.title,
            description: feedback.description,
            userName: userName,
            userEmail: userEmail,
            appVersion: feedback.appVersion ?? "Unknown",
            iosVersion: feedback.iosVersion ?? "Unknown",
            deviceModel: feedback.deviceModel ?? "Unknown"
        )

        do {
            try await supabase.functions.invoke(
                "send-feedback-email",
                options: .init(body: payload)
            )
        } catch {
            // Log but don't fail - email is secondary to saving feedback
            print("Failed to send feedback email: \(error)")
        }
    }

    // MARK: - Fetch User's Feedback

    func fetchUserFeedback(userId: UUID) async throws -> [Feedback] {
        let feedback: [Feedback] = try await supabase
            .from("feedback")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return feedback
    }

    // MARK: - Device Info

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private var iosVersion: String {
        return UIDevice.current.systemVersion
    }

    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? UIDevice.current.model
    }
}

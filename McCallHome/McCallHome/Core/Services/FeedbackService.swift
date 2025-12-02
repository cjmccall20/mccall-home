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

        try await supabase
            .from("feedback")
            .insert(feedback)
            .execute()

        return feedback
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

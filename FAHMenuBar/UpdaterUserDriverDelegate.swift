import Foundation
import AppKit
import Sparkle
import UserNotifications

//
// UpdaterUserDriverDelegate.swift
// FAHMenuBar
//
// Implements gentle reminders for Sparkle updates in a menu bar app.
// Provides non-intrusive update notifications via Dock badges and
// user notifications while respecting the background nature of the app.
//

class UpdaterUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {
    private weak var appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init()
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    // MARK: - Gentle Reminders Implementation
    
    func supportsGentleScheduledUpdateReminders() -> Bool {
        return true
    }
    
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        if handleShowingUpdate {
            // Show gentle reminder instead of standard update dialog
            showGentleUpdateReminder(for: update)
        }
    }
    
    private func showGentleUpdateReminder(for update: SUAppcastItem) {
        // Post user notification for gentle reminder
        postUpdateNotification(for: update)
    }
    
    
    // MARK: - User Notifications
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { granted, error in
            if let error = error {
                NSLog("FAHMenuBar: Notification permission error: \(error)")
            }
        }
    }
    
    private func postUpdateNotification(for update: SUAppcastItem) {
        let content = UNMutableNotificationContent()
        content.title = "FAH MenuBar Update Available"
        content.body = "Version \(update.displayVersionString) is ready to install. Click to update now."
        content.sound = UNNotificationSound.default
        content.userInfo = ["action": "show_update"]
        
        let request = UNNotificationRequest(
            identifier: "fah-update-available",
            content: content,
            trigger: nil // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("FAHMenuBar: Failed to post update notification: \(error)")
            }
        }
    }
    
    
    // MARK: - Update Completion Handling
    
    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["fah-update-available"])
    }
    
    func standardUserDriverWillFinishUpdateSession() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["fah-update-available"])
    }
    
}
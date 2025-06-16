//
//  SettingsView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct SettingsView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var settings: AppSettings // Add binding
    @Binding var readingGoal: ReadingGoal // Add binding
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $settings.colorScheme) {
                        Text("Light").tag(AppSettings.ColorScheme.light)
                        Text("Dark").tag(AppSettings.ColorScheme.dark)
                        Text("System").tag(AppSettings.ColorScheme.system)
                    }.pickerStyle(.segmented)
                    
                    Stepper("Font Size: \(Int(settings.preferredFontSize))",value: $settings.preferredFontSize,in: 14...24).pickerStyle(.segmented)
                    
                    Toggle("Show Reading Progress", isOn: $vm.appSettings.showReadingProgress)
                }
                
                Section("Reading Goals") {
                    Picker("Time Frame", selection: $vm.readingGoal.timeFrame) {
                        ForEach(ReadingGoal.TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.displayName).tag(timeFrame)
                        }
                    }
                    
                    Stepper("Target: \(vm.readingGoal.target) books",
                            value: $vm.readingGoal.target,
                            in: 1...100)
                }
                
                Section("Account") {
                    Toggle("Enable Notifications", isOn: $vm.appSettings.notificationsEnabled)
                    Toggle("Sync with iCloud", isOn: $vm.appSettings.syncWithCloud)
                }
                
                
                
                Button("Reset Reading Goal", role: .destructive) {
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

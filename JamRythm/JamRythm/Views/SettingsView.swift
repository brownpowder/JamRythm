//
//  SettingsView.swift
//  JamRythm
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        
                        // About this app
                        VStack(spacing: 16) {
                            sectionHeader(title: "ABOUT THIS APP")
                            
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.accentColor.opacity(0.8), Color.purple.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 70, height: 70)
                                        .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                                    
                                    Image(systemName: "guitars.fill")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 10)
                                
                                Text("Jam")
                                    .font(.title3.bold())
                                    .tracking(2)
                                
                                Text("Version \(appVersion)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 10)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // Developed by
                        VStack(spacing: 16) {
                            sectionHeader(title: "DEVELOPED BY")
                            
                            VStack(spacing: 1) {
                                HStack {
                                    Image(systemName: "music.note.house.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 20))
                                        .padding(.trailing, 8)
                                    
                                    Text("Takumi Kanaya & Gemini")
                                        .font(.body)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // Links
                        VStack(spacing: 16) {
                            sectionHeader(title: "LINKS")
                            
                            VStack(spacing: 1) {
                                settingsLinkRow(
                                    icon: "xmark",
                                    iconColor: .primary,
                                    title: "X (Twitter)",
                                    url: "https://twitter.com/ikatomape"
                                )
                                Divider().padding(.leading, 50)
                                settingsLinkRow(
                                    icon: "camera.fill",
                                    iconColor: .purple,
                                    title: "Instagram",
                                    url: "https://instagram.com/ikatomape"
                                )
                                Divider().padding(.leading, 50)
                                settingsLinkRow(
                                    icon: "play.rectangle.fill",
                                    iconColor: .red,
                                    title: "YouTube",
                                    url: "https://youtube.com/ikatomape"
                                )
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // Legal
                        VStack(spacing: 16) {
                            sectionHeader(title: "LEGAL")
                            
                            VStack(spacing: 1) {
                                settingsLinkRow(
                                    icon: "doc.text.fill",
                                    iconColor: .gray,
                                    title: "プライバシーポリシー",
                                    url: "https://example.com/privacy"
                                )
                                Divider().padding(.leading, 50)
                                settingsLinkRow(
                                    icon: "hand.raised.fill",
                                    iconColor: .gray,
                                    title: "利用規約",
                                    url: "https://example.com/terms"
                                )
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完了")
                            .font(.subheadline.bold())
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            Spacer()
        }
        .padding(.leading, 4)
    }
    
    private func settingsLinkRow(icon: String, iconColor: Color, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}

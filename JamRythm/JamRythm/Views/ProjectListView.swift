//
//  ProjectListView.swift
//  JamRythm
//

import SwiftUI

struct ProjectListView: View {
    @StateObject private var repository = ProjectRepository.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(repository.projects) { project in
                    NavigationLink(value: project) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(project.title)
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                Label("\(project.key.rawValue)", systemImage: "music.note")
                                Label("\(Int(project.bpm)) BPM", systemImage: "metronome")
                                Label(project.genre.rawValue, systemImage: project.genre.iconName)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Text(project.lastModified, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let project = repository.projects[index]
                        repository.delete(project)
                    }
                }
            }
            .navigationTitle("My Projects")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Project.self) { project in
                PlayEditorView(project: project)
            }
            .navigationDestination(for: String.self) { val in
                if val == "new" {
                    PlayEditorView(project: nil)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(value: "new") {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                repository.loadAllProjects()
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    // TODO: アプリの使い方ツアーを開始する処理
                }) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text("アプリの使い方を見る")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}
extension Project: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

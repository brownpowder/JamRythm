//
//  ProjectListView.swift
//  JamRythm
//

import SwiftUI

struct ProjectListView: View {
    @StateObject private var repository = ProjectRepository.shared
    @State private var showingNewProject = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(repository.projects, id: \.id) { (project: Project) in
                    NavigationLink {
                        PlayEditorView(viewModel: PlayEditorViewModel(project: project))
                    } label: {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        PlayEditorView(viewModel: PlayEditorViewModel(project: nil))
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                repository.loadAllProjects()
            }
        }
    }
}

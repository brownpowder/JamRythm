//
//  ProjectRepository.swift
//  JamRythm
//

import Foundation
import Combine

/*
Projectの永続化（保存・読み込み・削除）を担当するリポジトリ。
ドキュメントディレクトリ内にJSONファイルとして各プロジェクトを保存する。
*/
class ProjectRepository: ObservableObject {
    static let shared = ProjectRepository()
    
    @Published var projects: [Project] = []
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var projectsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Projects")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    init() {
        loadAllProjects()
    }
    
    // MARK: - Public Methods
    
    func generateNextProjectName() -> String {
        let prefix = "Project"
        var maxNumber = 0
        
        for project in projects {
            if project.title.hasPrefix(prefix) {
                let numberString = project.title.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
                if let number = Int(numberString) {
                    if number > maxNumber {
                        maxNumber = number
                    }
                }
            }
        }
        return "\(prefix)\(maxNumber + 1)"
    }

    
    func loadAllProjects() {
        var loadedProjects: [Project] = []
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil)
            for url in fileURLs where url.pathExtension == "json" {
                if let data = try? Data(contentsOf: url),
                   let project = try? decoder.decode(Project.self, from: data) {
                    loadedProjects.append(project)
                }
            }
        } catch {
            print("Failed to load projects: \(error)")
        }
        
        // 更新日時の降順（新しい順）でソート
        self.projects = loadedProjects.sorted(by: { $0.lastModified > $1.lastModified })
    }
    
    func save(_ project: Project) {
        var projectToSave = project
        projectToSave.lastModified = Date() // 保存時に最終更新日時を更新
        
        let url = fileURL(for: projectToSave.id)
        do {
            let data = try encoder.encode(projectToSave)
            try data.write(to: url, options: .atomic)
            
            // projects配列を更新
            if let index = projects.firstIndex(where: { $0.id == projectToSave.id }) {
                projects[index] = projectToSave
            } else {
                projects.insert(projectToSave, at: 0)
            }
            // 並び替えを維持
            projects.sort(by: { $0.lastModified > $1.lastModified })
        } catch {
            print("Failed to save project \(projectToSave.id): \(error)")
        }
    }
    
    func delete(_ project: Project) {
        let url = fileURL(for: project.id)
        do {
            try fileManager.removeItem(at: url)
            projects.removeAll(where: { $0.id == project.id })
        } catch {
            print("Failed to delete project \(project.id): \(error)")
        }
    }
    
    func duplicate(_ project: Project) {
        var newProject = project
        newProject.title = project.title + " (Copy)"
        // IDが違うので自動的に新しいファイルとして保存される
        save(newProject)
    }
    
    // MARK: - Private Helpers
    
    private func fileURL(for id: UUID) -> URL {
        return projectsDirectory.appendingPathComponent("\(id.uuidString).json")
    }
}

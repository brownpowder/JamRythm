//
//  ProjectModels.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Foundation

// MARK: - セクション種別

/*
楽曲内のセクション区分（曲の構成要素）を表す列挙型。
*/
enum SectionType: String, Codable, CaseIterable, Identifiable {
    case intro = "Intro"
    case verseA = "Aメロ"
    case verseB = "Bメロ"
    case chorus = "サビ"
    case bridge = "Bridge"
    case outro = "Outro"

    var id: String { rawValue }
}

// MARK: - コード候補モデル

/*
1つの小節に対して提示されるコード候補。
感情ラベル（ChordFlavor）と実際のコード情報を持つ。
*/
struct ChordCandidate: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let flavor: ChordFlavor
    let chord: Chord

    init(id: UUID = UUID(), flavor: ChordFlavor, chord: Chord) {
        self.id = id
        self.flavor = flavor
        self.chord = chord
    }
}

// MARK: - 小節モデル (Measure)

/*
楽曲の1小節ごとのデータを保持する構造体。
土台となる度数・ベース音、提示候補、ユーザーが選択したコードを管理する。
*/
struct Measure: Codable, Identifiable, Equatable {
    let id: UUID
    let baseDegree: Int
    let bassNote: String
    var chordCandidates: [ChordCandidate]
    var substituteCandidates: [SubstituteCandidate]
    var selectedChord: Chord?

    init(
        id: UUID = UUID(),
        baseDegree: Int,
        bassNote: String,
        chordCandidates: [ChordCandidate] = [],
        substituteCandidates: [SubstituteCandidate] = [],
        selectedChord: Chord? = nil
    ) {
        self.id = id
        self.baseDegree = baseDegree
        self.bassNote = bassNote
        self.chordCandidates = chordCandidates
        self.substituteCandidates = substituteCandidates
        self.selectedChord = selectedChord
    }

    /*
    小節に現在適用されている表示用コード（選択済みがあればそれを、無ければベース音コード）を返す。
    
    Arguments:
    なし
    
    Usage:
    タイムラインや特大コード表示で、小節ごとの現在のコードを取得するために使用される。
    */
    
    var activeChord: Chord {
        if let selected = selectedChord {
            return selected
        }
        if let firstCandidate = chordCandidates.first {
            return firstCandidate.chord
        }
        return Chord(rootNote: bassNote, type: "", bassNote: nil)
    }
}

// MARK: - セクションモデル (Section)

/*
楽曲のセクション（小節の集合）を表す構造体。
*/
struct Section: Codable, Identifiable, Equatable {
    let id: UUID
    var type: SectionType
    var measures: [Measure]

    init(id: UUID = UUID(), type: SectionType, measures: [Measure] = []) {
        self.id = id
        self.type = type
        self.measures = measures
    }
}

// MARK: - プロジェクトモデル (Project)

/*
楽曲全体の設定と構成データを保持する最上位構造体。
*/
struct Project: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var bpm: Double
    var key: Key
    var sections: [Section]

    init(
        id: UUID = UUID(),
        title: String = "Untitled Jam",
        bpm: Double = 120.0,
        key: Key = .C,
        sections: [Section] = []
    ) {
        self.id = id
        self.title = title
        self.bpm = bpm
        self.key = key
        self.sections = sections
    }
}

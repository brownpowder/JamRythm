//
//  PlayerEngineProtocols.swift
//  JamRythm
//

import Foundation

/*
ドラムプレイヤーの演奏ロジックを定義するプロトコル。
*/
protocol DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent]
}

/*
ベースプレイヤーの演奏ロジックを定義するプロトコル。
*/
protocol BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent]
}

/*
ピアノプレイヤーの演奏ロジックを定義するプロトコル。
*/
protocol PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent]
}

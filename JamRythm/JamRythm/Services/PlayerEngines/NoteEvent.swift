//
//  NoteEvent.swift
//  JamRythm
//

import Foundation

/*
Player Engineが評価した結果として返す、発音すべき音符データの構造体。
Samplerに渡すための情報（ノート番号とベロシティ）を持つ。
*/
struct NoteEvent: Equatable {
    let note: UInt8
    let velocity: UInt8
    let channel: UInt8
    let isShortRelease: Bool // ピアノのスタッカート等のために追加

    init(note: UInt8, velocity: UInt8, channel: UInt8 = 0, isShortRelease: Bool = false) {
        self.note = note
        self.velocity = velocity
        self.channel = channel
        self.isShortRelease = isShortRelease
    }
}

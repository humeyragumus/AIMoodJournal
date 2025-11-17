//
//  MoodEntry.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 01.11.2025.
//


//  Kullanıcının günlük entry'sini temsil eden ana model
//  Her gün bir tane oluşturuluyor
//

import Foundation
import SwiftUI

// Günlük entry modeli - kullanıcının o gün yazdığı her şey burada
struct MoodEntry: Identifiable, Codable {
    var id: UUID                    // Her entry için unique ID
    var date: Date                  // Entry tarihi
    var text: String                // Kullanıcının yazdığı metin
    var moodData: MoodData?         // AI'dan gelen analiz sonucu (opsiyonel - analiz henüz yapılmamış olabilir)
    var artworkColors: [String]?    // Generated artwork için kullanılan renkler (hex formatında)
    
    // Yeni entry oluşturmak için
    init(id: UUID = UUID(), date: Date = Date(), text: String = "", moodData: MoodData? = nil, artworkColors: [String]? = nil) {
        self.id = id
        self.date = date
        self.text = text
        self.moodData = moodData
        self.artworkColors = artworkColors
    }
    
    // Tarihi "11 Kasım 2025" formatında döndürüyor
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    // Tarihi "11 Kas" formatında döndürüyor - calendar view için
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    // Entry'nin analize gönderilip gönderilmediğini kontrol ediyorum
    var isAnalyzed: Bool {
        return moodData != nil
    }
}

// MARK: - Preview için örnek data
extension MoodEntry {
    // Xcode preview'larda kullanmak için örnek entry'ler
    static let example = MoodEntry(
        date: Date(),
        text: "Bugün harika bir gündü! Projeyi bitirdim ve çok mutluyum. Akşam arkadaşlarla buluştuk.",
        moodData: MoodData.example
    )
    
    static let exampleSad = MoodEntry(
        date: Date().addingTimeInterval(-86400), // Dün
        text: "Bugün biraz yorgunum ve üzgünüm. İşler planladığım gibi gitmedi.",
        moodData: MoodData(
            mood: .sad,
            energy: 0.3,
            sentiment: -0.6,
            keywords: ["yorgun", "üzgün", "planlar"],
            aiSummary: "Kullanıcı yorgun ve üzgün hissediyor."
        )
    )
}

//
//  MoodData.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 01.11.2025.
//
//  AI analiz sonucunu tutan model
//  Claude API'den gelen verileri burada saklıyorum
//

import Foundation

// AI'ın analiz ettiği mood verilerini tutan struct
struct MoodData: Codable {
    var mood: MoodType              // Ana ruh hali (mutlu, üzgün, vs.)
    var energy: Double              // Enerji seviyesi 0.0 - 1.0 arası
    var sentiment: Double           // Duygusal ton -1.0 (negatif) ile 1.0 (pozitif) arası
    var keywords: [String]          // Metinden çıkarılan anahtar kelimeler
    var aiSummary: String           // AI'ın yaptığı kısa özet
    
    // Yeni MoodData oluşturmak için
    init(mood: MoodType, energy: Double, sentiment: Double, keywords: [String], aiSummary: String) {
        self.mood = mood
        self.energy = energy
        self.sentiment = sentiment
        self.keywords = keywords
        self.aiSummary = aiSummary
    }
    
    // Sentiment'e göre pozitif mi negatif mi kontrol ediyorum
    var isPositive: Bool {
        return sentiment > 0
    }
    
    // Enerji seviyesini yüzde olarak döndürüyorum
    var energyPercentage: Int {
        return Int(energy * 100)
    }
    
    // Sentiment'i yüzde olarak döndürüyorum (0-100 arası)
    var sentimentPercentage: Int {
        // -1 ile 1 arasını 0 ile 100 arasına çeviriyorum
        return Int((sentiment + 1) * 50)
    }
}

// MARK: - Preview için örnek data
extension MoodData {
    // Xcode preview'larda kullanmak için örnek mood data
    static let example = MoodData(
        mood: .happy,
        energy: 0.8,
        sentiment: 0.9,
        keywords: ["harika", "mutlu", "proje", "arkadaşlar"],
        aiSummary: "Kullanıcı başarılı bir gün geçirmiş ve mutlu hissediyor. Sosyal aktiviteler enerji seviyesini artırmış."
    )
    
    static let exampleCalm = MoodData(
        mood: .calm,
        energy: 0.5,
        sentiment: 0.3,
        keywords: ["sakin", "dingin", "yoga"],
        aiSummary: "Kullanıcı sakin ve dengeli bir ruh hali içinde."
    )
    
    static let exampleAnxious = MoodData(
        mood: .anxious,
        energy: 0.7,
        sentiment: -0.4,
        keywords: ["endişeli", "stresli", "iş", "toplantı"],
        aiSummary: "Kullanıcı iş yüküyle ilgili endişeli ve stresli hissediyor."
    )
}

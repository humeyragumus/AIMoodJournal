//
//  Constants.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 01.11.2025.
//
//  Tüm uygulama sabitlerini buradan yönetiyorum
//  Renkler, fontlar, mood tipleri vs. hepsi burada
//

import SwiftUI

// MARK: - Ruh Hali Tipleri
// Kullanıcının seçebileceği tüm ruh hali kategorilerini burada tanımladım
enum MoodType: String, CaseIterable, Codable {
    case happy = "Mutlu"
    case calm = "Sakin"
    case sad = "Üzgün"
    case anxious = "Kaygılı"
    case energetic = "Enerjik"
    case peaceful = "Huzurlu"
    case excited = "Heyecanlı"
    case neutral = "Nötr"
    
    // Her mood'un ismini döndürüyorum
    var name: String {
        return self.rawValue
    }
    
    // Her mood için emoji döndürüyorum - UI'da kullanmak için
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .calm: return "😌"
        case .sad: return "😢"
        case .anxious: return "😰"
        case .energetic: return "⚡️"
        case .peaceful: return "🕊️"
        case .excited: return "🤩"
        case .neutral: return "😐"
        }
    }
}

// MARK: - Renk Paleti
// Kahve, vizon ve toprak tonları - warm, cozy ve sofistike
struct AppColors {
    // Arka plan renkleri - kahverengi tonlarında warm tema
    static let background = Color(hex: "1C1612")        // Koyu kahverengi - çok warm
    static let surface = Color(hex: "2A221B")           // Kartlar için - açık kahve
    static let surfaceLight = Color(hex: "3A2E24")      // Yükseltilmiş elementler - vizon
    
    // Ana brand renkleri - toprak tonları palette
    static let primary = Color(hex: "D4A574")           // Altın sarısı/bal rengi - ana renk
    static let secondary = Color(hex: "C9A88A")         // Vizon/bej - ikincil
    static let accent = Color(hex: "B8906B")            // Kahve sütü - vurgu
    
    // Mood görselleştirme renkleri - doğal tonlar
    static let moodPink = Color(hex: "E8B4A8")          // Pudra/gül kurusu
    static let moodBlue = Color(hex: "A8C5D6")          // Pastel mavi
    static let moodGreen = Color(hex: "B5C9A8")         // Soft yeşil/zeytin
    static let moodYellow = Color(hex: "F4E4C1")        // Krem/vanilya
    static let moodPurple = Color(hex: "C5B3CC")        // Lavanta
    static let moodPeach = Color(hex: "E8C5B3")         // Şeftali/terracotta
    
    // Text renkleri - opacity ile hiyerarşi oluşturdum
    static let textPrimary = Color.white.opacity(0.95)      // Ana metinler
    static let textSecondary = Color.white.opacity(0.7)     // İkincil metinler
    static let textTertiary = Color.white.opacity(0.5)      // Caption'lar
    
    // Her mood için özel gradient döndürüyorum - mood art'larda kullanacağım
    static func getMoodGradient(for mood: MoodType) -> LinearGradient {
        let colors: [Color]
        
        // Her mood'a uygun renk kombinasyonları seçtim
        switch mood {
        case .happy:
            colors = [moodYellow, moodPeach, moodPink]      // Sıcak, neşeli tonlar
        case .calm:
            colors = [moodBlue, moodGreen]                  // Sakin, soğuk tonlar
        case .sad:
            colors = [moodBlue, moodPurple]                 // Hüzünlü, soğuk
        case .anxious:
            colors = [moodPink, moodPurple]                 // Gergin, yoğun
        case .energetic:
            colors = [moodYellow, moodGreen, moodPeach]     // Canlı, dinamik
        case .peaceful:
            colors = [moodBlue, moodPurple.opacity(0.7)]    // Huzurlu, yumuşak
        case .excited:
            colors = [moodPink, moodYellow, moodPeach]      // Heyecanlı, parlak
        case .neutral:
            colors = [Color.gray.opacity(0.3), Color.gray.opacity(0.5)]  // Nötr, sade
        }
        
        // Gradient'i çapraz olarak veriyorum - daha estetik duruyor
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Mood'a göre ana renk döndürüyorum - glow effect'ler için
    static func getDominantColor(for mood: MoodType) -> Color {
        switch mood {
        case .happy:
            return moodYellow
        case .calm:
            return moodBlue
        case .sad:
            return moodPurple
        case .anxious:
            return moodPink
        case .energetic:
            return moodGreen
        case .peaceful:
            return moodBlue
        case .excited:
            return moodPeach
        case .neutral:
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Font Sistemi
// Typography - tüm fontları rounded design olarak ayarladım, daha soft görünüyor
struct AppFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
}

// MARK: - Boşluk Değerleri
// Tutarlı spacing için - her yerde aynı değerleri kullanıyorum
struct AppSpacing {
    static let xs: CGFloat = 4      // Çok küçük boşluklar
    static let sm: CGFloat = 8      // Küçük boşluklar
    static let md: CGFloat = 16     // Orta - en çok kullanılan
    static let lg: CGFloat = 24     // Büyük boşluklar
    static let xl: CGFloat = 32     // Çok büyük boşluklar
}

// MARK: - Border Radius
// Corner radius değerleri - yumuşak köşeler için
struct AppRadius {
    static let sm: CGFloat = 8      // Küçük elementler (buttonlar)
    static let md: CGFloat = 12     // Orta (input fieldlar)
    static let lg: CGFloat = 20     // Büyük (kartlar)
    static let xl: CGFloat = 28     // Çok büyük (modal'lar)
}

// MARK: - Hex Color Desteği
// String'den Color oluşturabilmek için extension yazdım
// Örnek: Color(hex: "FF5733") şeklinde kullanabiliyorum
extension Color {
    init(hex: String) {
        // Hex string'i temizliyorum - sadece rakam ve harf kalsın
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        // Hex formatına göre parse ediyorum (RGB veya ARGB)
        switch hex.count {
        case 3:     // RGB (12-bit) - örn: "F00"
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:     // RGB (24-bit) - örn: "FF0000"
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:     // ARGB (32-bit) - örn: "FFFF0000"
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:    // Geçersiz format - varsayılan beyaz
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        // 0-255 aralığını 0-1 aralığına çeviriyorum
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

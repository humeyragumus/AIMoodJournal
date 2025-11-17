//
//  GeminiService.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 05.11.2025.
//
//  Google Gemini API ile mood analizi yapıyorum
//  Kullanıcının günlük metnini AI'a gönderiyor, ruh hali analizi alıyor
//

import Foundation

// MARK: - Gemini Service
/// Google Gemini AI ile ruh hali analizi yapan singleton service
/// Kullanıcının yazdığı metni Gemini'ye gönderiyor ve MoodData döndürüyor
class GeminiService {
    // Singleton instance - uygulama boyunca tek bir GeminiService var
    static let shared = GeminiService()
    
    // Private init - sadece singleton kullanılabilir
    private init() {}
    
    // ⚠️ API KEY - Config.swift'ten alınıyor (güvenlik için)
    private var apiKey = Config.geminiAPIKey
    
    // Gemini API endpoint URL'i
    private let endpoint = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"
    
    // MARK: - Main Analysis Function
    /// Ana fonksiyon - kullanıcının metnini analiz edip MoodData döndürüyor
    /// - Parameter text: Kullanıcının yazdığı günlük metni
    /// - Returns: AI tarafından analiz edilmiş MoodData
    func analyzeMood(text: String) async throws -> MoodData {
        // URL oluşturuyorum (API key query parameter olarak ekleniyor)
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiError.invalidURL
        }
        
        // API key'i URL'e ekliyorum
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }
        
        // HTTP request oluşturuyorum
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prompt - Gemini'ye ne yapmasını istediğimi anlatıyorum
        // AI'dan istediğim format ve kuralları belirtiyorum
        let prompt = """
        Aşağıdaki günlük metnini analiz et ve SADECE JSON formatında cevap ver:
        
        {
          "mood": "happy",
          "energy": 0.8,
          "sentiment": 0.9,
          "keywords": ["mutlu", "pozitif", "enerjik"],
          "summary": "Kullanıcı bugün mutlu ve enerjik hissediyor."
        }
        
        mood değerleri: happy, calm, sad, anxious, energetic, peaceful, excited, neutral
        energy: 0.0 - 1.0 arası
        sentiment: -1.0 ile 1.0 arası
        keywords: maksimum 5 anahtar kelime
        summary: 1-2 cümle Türkçe özet
        
        SADECE JSON döndür, başka hiçbir şey yazma!
        
        Analiz edilecek metin:
        \(text)
        """
        
        // Request body'yi JSON formatında hazırlıyorum
        // Gemini API'nin beklediği format bu
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        // Body'yi JSON data'ya çeviriyorum
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // API'ye istek gönderiyorum (async/await ile)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Response'un HTTP olup olmadığını kontrol ediyorum
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        // Status code kontrolü (200 = başarılı)
        if httpResponse.statusCode != 200 {
            // Hata mesajını console'a yazdırıyorum (debug için)
            if let errorString = String(data: data, encoding: .utf8) {
                print("Gemini API Error: \(errorString)")
            }
            throw GeminiError.invalidResponse
        }
        
        // Response'u GeminiResponse objesine parse ediyorum
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        // Gemini'nin döndürdüğü text'i çıkarıyorum
        guard let candidate = geminiResponse.candidates.first,
              let part = candidate.content.parts.first,
              let responseText = part.text else {
            throw GeminiError.noContent
        }
        
        // JSON'dan önce/sonra gelen gereksiz karakterleri temizliyorum
        // Gemini bazen ```json``` ile sarmalıyor, bunları siliyorum
        let cleanedText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Temizlenmiş JSON string'i MoodAnalysis objesine çeviriyorum
        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.decodingError
        }
        
        let moodAnalysis = try JSONDecoder().decode(MoodAnalysis.self, from: jsonData)
        
        // İngilizce mood değerini Türkçe MoodType'a çeviriyorum
        let moodType = mapEnglishMoodToTurkish(moodAnalysis.mood)
        print("🔍 Gemini'nin döndürdüğü mood: \(moodAnalysis.mood)")
        print("🔍 Parse edilen MoodType: \(moodType.rawValue)")
        
        // MoodAnalysis'i uygulamamızın MoodData formatına çeviriyorum
        return MoodData(
            mood: moodType,
            energy: moodAnalysis.energy,
            sentiment: moodAnalysis.sentiment,
            keywords: moodAnalysis.keywords,
            aiSummary: moodAnalysis.summary
        )
    }
    
    // MARK: - Helper Functions
    /// İngilizce mood string'ini Türkçe MoodType enum'ına çeviriyor
    /// Gemini İngilizce döndürüyor, ben Türkçe enum kullanıyorum
    private func mapEnglishMoodToTurkish(_ englishMood: String) -> MoodType {
        switch englishMood.lowercased() {
        case "happy":
            return .happy
        case "calm":
            return .calm
        case "sad":
            return .sad
        case "anxious":
            return .anxious
        case "energetic":
            return .energetic
        case "peaceful":
            return .peaceful
        case "excited":
            return .excited
        default:
            return .neutral // Anlamadıysa neutral yapıyorum
        }
    }
}

// MARK: - Response Models
// Gemini API'den gelen response'u parse etmek için model'ler

/// Gemini API'nin döndürdüğü ana response yapısı
struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

/// Response içindeki candidate (AI'ın ürettiği cevap seçenekleri)
struct Candidate: Codable {
    let content: Content
}

/// Candidate içindeki content
struct Content: Codable {
    let parts: [Part]
}

/// Content içindeki part (asıl metin burada)
struct Part: Codable {
    let text: String?
}

/// AI'ın döndürdüğü JSON formatındaki mood analizi
/// Bu, Gemini'nin ürettiği JSON'u parse etmek için kullanılıyor
struct MoodAnalysis: Codable {
    let mood: String        // "happy", "sad", vs.
    let energy: Double      // 0.0 - 1.0
    let sentiment: Double   // -1.0 - 1.0
    let keywords: [String]  // ["mutlu", "enerjik", ...]
    let summary: String     // AI'ın yazdığı özet
}

// MARK: - Error Handling
/// Gemini Service'de oluşabilecek hatalar
enum GeminiError: LocalizedError {
    case invalidURL          // URL oluşturulamadı
    case invalidResponse     // API'den geçersiz cevap geldi
    case noContent          // API cevabı boş
    case decodingError      // JSON parse edilemedi
    
    // Hata mesajlarını Türkçe olarak döndürüyor
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "API'den geçersiz yanıt alındı"
        case .noContent:
            return "API'den içerik alınamadı"
        case .decodingError:
            return "Veri parse edilemedi"
        }
    }
}

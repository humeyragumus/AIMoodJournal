//
//  SuggestionEngine.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 11.11.2025.
//
//  AI Önerileri Motoru
//  Kullanıcının mood'una göre kişiselleştirilmiş öneriler üretiyor
//  MoodResultSheet'te gösterilen aktivite önerileri bu engine'den geliyor
//

import SwiftUI

// MARK: - Suggestion Engine
/// Mood analiz sonuçlarına göre kullanıcıya özel öneriler üreten singleton class
/// Her ruh hali için farklı aktivite, wellness ve self-care önerileri içeriyor
class SuggestionEngine {
    
    // Singleton instance - uygulama boyunca tek bir SuggestionEngine var
    static let shared = SuggestionEngine()
    
    // Private init - sadece singleton kullanılabilir
    private init() {}
    
    // MARK: - Suggestion Model
    /// Tek bir öneri modeli
    /// Her öneri bir ikon, başlık, açıklama ve kategori içeriyor
    struct Suggestion: Identifiable {
        let id = UUID()
        let icon: String           // SF Symbol icon adı
        let title: String          // Öneri başlığı
        let description: String    // Detaylı açıklama
        let color: Color          // Renk (mood'a göre değişiyor)
        let category: Category    // Öneri kategorisi
        
        /// Öneri kategorileri
        enum Category: String {
            case wellness = "Sağlık"
            case activity = "Aktivite"
            case relaxation = "Rahatlama"
            case social = "Sosyal"
            case mindfulness = "Farkındalık"
            case creative = "Yaratıcılık"
            case selfCare = "Öz Bakım"
        }
    }
    
    // MARK: - Generate Suggestions
    
    /// Mood analiz sonucuna göre öneriler üret
    /// MoodResultSheet açıldığında bu fonksiyon çağrılıyor
    /// - Parameters:
    ///   - mood: Tespit edilen ruh hali (happy, sad, anxious, vs.)
    ///   - energy: Enerji seviyesi (0-10 arası)
    ///   - sentiment: Duygu tonu (-1 ile +1 arası, negatif/pozitif)
    /// - Returns: Kullanıcıya özel 3-5 öneri döndürür
    func generateSuggestions(
        mood: MoodType,
        energy: Double,
        sentiment: Double
    ) -> [Suggestion] {
        
        var suggestions: [Suggestion] = []
        
        // 1. Mood'a özel öneriler (en önemli)
        suggestions.append(contentsOf: getMoodSpecificSuggestions(mood: mood))
        
        // 2. Enerji seviyesine göre öneriler
        suggestions.append(contentsOf: getEnergySuggestions(energy: energy))
        
        // 3. Sentiment'a göre öneriler (pozitif/negatif)
        suggestions.append(contentsOf: getSentimentSuggestions(sentiment: sentiment))
        
        // 4. Genel wellness önerileri (su içmek, uyku, vs.)
        suggestions.append(contentsOf: getGeneralWellnessSuggestions())
        
        // Maksimum 5 öneri döndür (fazlaysa rastgele seç)
        return Array(suggestions.shuffled().prefix(5))
    }
    
    // MARK: - Mood Specific Suggestions
    
    /// Her ruh hali için özel hazırlanmış öneriler
    /// En kişiselleştirilmiş öneriler buradan geliyor
    private func getMoodSpecificSuggestions(mood: MoodType) -> [Suggestion] {
        switch mood {
            
        case .happy:
            // Mutlu kullanıcıya enerjiyi koruma ve paylaşma önerileri
            return [
                Suggestion(
                    icon: "sparkles",
                    title: "Bu Enerjiyi Koruyun",
                    description: "Bugünün pozitif enerjisini günlüğüne yaz, yarın hatırla",
                    color: AppColors.moodYellow,
                    category: .mindfulness
                ),
                Suggestion(
                    icon: "figure.walk",
                    title: "Dışarı Çık",
                    description: "Güzel havanın tadını çıkar, kısa bir yürüyüş yap",
                    color: AppColors.moodGreen,
                    category: .activity
                ),
                Suggestion(
                    icon: "person.2.fill",
                    title: "Sevdiklerinle Paylaş",
                    description: "Bu mutluluğu yakınlarınla paylaş, onları ara",
                    color: AppColors.moodPink,
                    category: .social
                )
            ]
            
        case .calm:
            // Sakin kullanıcıya bu huzurlu anı değerlendirme önerileri
            return [
                Suggestion(
                    icon: "book.fill",
                    title: "Kitap Oku",
                    description: "Bu sakin anın tadını çıkar, sevdiğin bir kitap aç",
                    color: AppColors.moodBlue,
                    category: .relaxation
                ),
                Suggestion(
                    icon: "paintbrush.fill",
                    title: "Yaratıcı Ol",
                    description: "Resim yap, yaz veya müzik dinle",
                    color: AppColors.moodPurple,
                    category: .creative
                ),
                Suggestion(
                    icon: "leaf.fill",
                    title: "Meditasyon",
                    description: "10 dakikalık nefes egzersizi yap",
                    color: AppColors.moodGreen,
                    category: .mindfulness
                )
            ]
            
        case .sad:
            // Üzgün kullanıcıya kendine nazik olma ve destek bulma önerileri
            return [
                Suggestion(
                    icon: "heart.fill",
                    title: "Kendine Nazik Ol",
                    description: "Üzgün hissetmek normal, duygularını kabul et",
                    color: AppColors.moodPink,
                    category: .selfCare
                ),
                Suggestion(
                    icon: "phone.fill",
                    title: "Birisiyle Konuş",
                    description: "Güvendiğin birine ulaş, yalnız değilsin",
                    color: AppColors.moodBlue,
                    category: .social
                ),
                Suggestion(
                    icon: "music.note",
                    title: "Sevdiğin Müziği Dinle",
                    description: "Müzik ruhuna iyi gelir, favori şarkını çal",
                    color: AppColors.moodPurple,
                    category: .relaxation
                ),
                Suggestion(
                    icon: "cup.and.saucer.fill",
                    title: "Sıcak İçecek",
                    description: "Kendine bir çay veya kahve yap, rahatla",
                    color: AppColors.moodPeach,
                    category: .selfCare
                )
            ]
            
        case .anxious:
            // Endişeli kullanıcıya rahatlama ve zihin dinginliği önerileri
            return [
                Suggestion(
                    icon: "wind",
                    title: "Derin Nefes Al",
                    description: "4-7-8 tekniği: 4 sn nefes al, 7 sn tut, 8 sn ver",
                    color: AppColors.moodBlue,
                    category: .mindfulness
                ),
                Suggestion(
                    icon: "figure.mind.and.body",
                    title: "Yoga veya Meditasyon",
                    description: "10 dakikalık guided meditation dene",
                    color: AppColors.moodPurple,
                    category: .wellness
                ),
                Suggestion(
                    icon: "pencil.and.list.clipboard",
                    title: "Endişelerini Yaz",
                    description: "Kafandakileri kağıda dök, organize ol",
                    color: AppColors.moodPink,
                    category: .mindfulness
                ),
                Suggestion(
                    icon: "leaf.fill",
                    title: "Doğada Vakit Geçir",
                    description: "Yeşillik seni sakinleştirir, park'a git",
                    color: AppColors.moodGreen,
                    category: .activity
                )
            ]
            
        case .energetic:
            // Enerjik kullanıcıya bu enerjiyi kullanma önerileri
            return [
                Suggestion(
                    icon: "figure.run",
                    title: "Egzersiz Yap",
                    description: "Bu enerjiyi kullanan, 20 dk koşu veya spor",
                    color: AppColors.moodGreen,
                    category: .activity
                ),
                Suggestion(
                    icon: "checkmark.circle.fill",
                    title: "Ertelediğin İşleri Yap",
                    description: "Motivasyonun yüksek, o işi şimdi bitir!",
                    color: AppColors.moodYellow,
                    category: .activity
                ),
                Suggestion(
                    icon: "sparkles",
                    title: "Yeni Bir Şey Dene",
                    description: "Hobini geliştir veya yeni bir şey öğren",
                    color: AppColors.moodPeach,
                    category: .creative
                )
            ]
            
        case .peaceful:
            // Huzurlu kullanıcıya bu anı değerlendirme önerileri
            return [
                Suggestion(
                    icon: "moon.stars.fill",
                    title: "Mindfulness",
                    description: "Bu huzurlu anın tadını çıkar, şükret",
                    color: AppColors.moodBlue,
                    category: .mindfulness
                ),
                Suggestion(
                    icon: "book.closed.fill",
                    title: "Günlük Tut",
                    description: "Bu huzuru yarın hatırlamak için kaydet",
                    color: AppColors.moodPurple,
                    category: .mindfulness
                ),
                Suggestion(
                    icon: "sun.max.fill",
                    title: "Doğanın Tadını Çıkar",
                    description: "Dışarı çık, güneşi hisset",
                    color: AppColors.moodYellow,
                    category: .relaxation
                )
            ]
            
        case .excited:
            // Heyecanlı kullanıcıya bu heyecanı paylaşma önerileri
            return [
                Suggestion(
                    icon: "party.popper.fill",
                    title: "Bu Heyecanı Paylaş",
                    description: "Sevdiklerinle bu güzel haberi paylaş!",
                    color: AppColors.moodPink,
                    category: .social
                ),
                Suggestion(
                    icon: "camera.fill",
                    title: "Anıları Kaydet",
                    description: "Fotoğraf çek, bu anı ölümsüzleştir",
                    color: AppColors.moodYellow,
                    category: .creative
                ),
                Suggestion(
                    icon: "gift.fill",
                    title: "Kendine Ödül Ver",
                    description: "Bu başarıyı kutlamayı hak ediyorsun!",
                    color: AppColors.moodPeach,
                    category: .selfCare
                )
            ]
            
        case .neutral:
            // Nötr kullanıcıya hafif aktivasyon önerileri
            return [
                Suggestion(
                    icon: "figure.walk",
                    title: "Hareket Et",
                    description: "Kısa bir yürüyüş enerji verir",
                    color: AppColors.moodGreen,
                    category: .activity
                ),
                Suggestion(
                    icon: "cup.and.saucer.fill",
                    title: "Mola Ver",
                    description: "Bir kahve molası zihnini temizler",
                    color: AppColors.moodPeach,
                    category: .selfCare
                )
            ]
        }
    }
    
    // MARK: - Energy Suggestions
    
    /// Enerji seviyesine göre öneriler
    /// Düşük enerjiye dinlenme, yüksek enerjiye aktivite önerileri
    private func getEnergySuggestions(energy: Double) -> [Suggestion] {
        if energy < 3 {
            // Düşük enerji - dinlenme önerileri
            return [
                Suggestion(
                    icon: "bed.double.fill",
                    title: "Dinlen",
                    description: "Enerjin düşük, kendine zaman ayır ve dinlen",
                    color: AppColors.moodBlue,
                    category: .wellness
                ),
                Suggestion(
                    icon: "powersleep",
                    title: "Erken Yat",
                    description: "Bu gece erken uyu, yarın daha enerjik olursun",
                    color: AppColors.moodPurple,
                    category: .wellness
                ),
                Suggestion(
                    icon: "drop.fill",
                    title: "Su İç",
                    description: "Susuzluk yorgunluk yapar, bol su iç",
                    color: AppColors.moodBlue,
                    category: .wellness
                )
            ]
        } else if energy > 7 {
            // Yüksek enerji - aktivite önerileri
            return [
                Suggestion(
                    icon: "figure.strengthtraining.traditional",
                    title: "Enerjini Kullan",
                    description: "Spor yap veya aktif bir iş yap",
                    color: AppColors.moodGreen,
                    category: .activity
                ),
                Suggestion(
                    icon: "lightbulb.fill",
                    title: "Yaratıcı Projeler",
                    description: "Bu enerjiyi yaratıcı işlere yönlendir",
                    color: AppColors.moodYellow,
                    category: .creative
                )
            ]
        } else {
            // Orta enerji - öneri yok
            return []
        }
    }
    
    // MARK: - Sentiment Suggestions
    
    /// Duygu tonuna göre öneriler
    /// Negatif tona pozitiflik, pozitif tona koruma önerileri
    private func getSentimentSuggestions(sentiment: Double) -> [Suggestion] {
        if sentiment < -0.3 {
            // Negatif ton - pozitiflik bulma önerileri
            return [
                Suggestion(
                    icon: "heart.circle.fill",
                    title: "Kendine İyi Bak",
                    description: "Zor bir gün geçiriyorsun, kendine nazik ol",
                    color: AppColors.moodPink,
                    category: .selfCare
                ),
                Suggestion(
                    icon: "sun.max.fill",
                    title: "Pozitif Şeyler Bul",
                    description: "3 şükrettiğin şeyi düşün, küçük mutluluklar önemli",
                    color: AppColors.moodYellow,
                    category: .mindfulness
                )
            ]
        } else if sentiment > 0.3 {
            // Pozitif ton - koruma önerileri
            return [
                Suggestion(
                    icon: "star.fill",
                    title: "Bu Pozitifliği Koru",
                    description: "Ne yaptığını not et, tekrar et!",
                    color: AppColors.moodYellow,
                    category: .mindfulness
                )
            ]
        } else {
            // Nötr ton - öneri yok
            return []
        }
    }
    
    // MARK: - General Wellness
    
    /// Genel sağlık önerileri
    /// Her zaman uygulanabilecek temel wellness tavsiyeleri
    private func getGeneralWellnessSuggestions() -> [Suggestion] {
        let allSuggestions = [
            Suggestion(
                icon: "drop.fill",
                title: "Hidrasyon",
                description: "Günde en az 8 bardak su içmeyi unutma",
                color: AppColors.moodBlue,
                category: .wellness
            ),
            Suggestion(
                icon: "fork.knife",
                title: "Sağlıklı Beslen",
                description: "Dengeli beslenmek ruh halini etkiler",
                color: AppColors.moodGreen,
                category: .wellness
            ),
            Suggestion(
                icon: "moon.zzz.fill",
                title: "Uyku Düzeni",
                description: "Her gün aynı saatte yat ve kalk",
                color: AppColors.moodPurple,
                category: .wellness
            )
        ]
        
        // 1 tane rastgele genel öneri ekle
        return Array(allSuggestions.shuffled().prefix(1))
    }
}

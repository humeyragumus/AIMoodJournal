//
//  NotificationManager.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 09.11.2025.
//
//  Bildirim yönetimi için manager class
//  Kullanıcıya günlük yazma hatırlatıcıları gönderiyor
//  Motivasyon sözleri ve özelleştirilebilir zamanlamalar içeriyor
//

import SwiftUI
import UserNotifications
import Combine

// MARK: - Notification Manager
/// Uygulama genelinde bildirim yönetimini sağlayan singleton class
/// Push notification'ları planlar, iptal eder ve ayarlarını yönetir
class NotificationManager: ObservableObject {
    
    // Singleton instance - uygulamada tek bir NotificationManager olması için
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    // Bu değişkenler değiştiğinde UI otomatik güncelleniyor (@Published sayesinde)
    
    /// Hatırlatıcıların açık/kapalı durumu
    @Published var isEnabled = false
    
    /// Kullanıcının seçtiği hatırlatma saati
    @Published var selectedTime = Date()
    
    /// Motivasyon sözlerinin gösterilip gösterilmeyeceği
    @Published var motivationalQuotesEnabled = true
    
    /// Hatırlatıcıların ne sıklıkta gönderileceği (her gün, hafta içi, vb.)
    @Published var reminderFrequency: ReminderFrequency = .daily
    
    // MARK: - Motivasyon Sözleri
    /// Bildirimlerde gösterilecek ilham verici mesajlar koleksiyonu
    /// Her bildirimde rastgele bir söz seçiliyor
    private let motivationalQuotes = [
        "Günlüğüne bugünün duygularını yaz, yarın için bir hazine olacak 📝",
        "Kendini ifade etmek güçtür. Bugün nasıl hissediyorsun? 💭",
        "Her duygu değerlidir. Bugünkü hikayeni paylaşmaya ne dersin? ✨",
        "Duygularını yazmak, onları anlamanın ilk adımıdır 🌟",
        "Bugün için minnettarlık duyduğun bir şey var mı? 🙏",
        "Kendine 5 dakika ayır, duygularını keşfet 🕊️",
        "Yazarak iyileş, her kelime bir adım 🌱",
        "Bugünün küçük mutluluklarını kaydet 😊",
        "İç dünyanı keşfetmeye hazır mısın? 🎨",
        "Duygularını yazmak, zihnini temizler 🧘‍♀️"
    ]
    
    // MARK: - Reminder Frequency Enum
    /// Hatırlatıcı sıklığını belirleyen enum
    /// Her seçenek için hangi günlerde bildirim gönderileceğini tanımlıyor
    enum ReminderFrequency: String, CaseIterable {
        case daily = "Her Gün"       // Haftanın 7 günü
        case weekdays = "Hafta İçi"  // Pazartesi-Cuma
        case weekends = "Hafta Sonu" // Cumartesi-Pazar
        case custom = "Özel"         // Kullanıcı tanımlı (şimdilik kullanılmıyor)
        
        /// Seçilen frekansa göre bildirim gönderilecek günleri döndürüyor
        /// iOS takviminde: 1=Pazar, 2=Pazartesi, 3=Salı, 4=Çarşamba, 5=Perşembe, 6=Cuma, 7=Cumartesi
        /// - Returns: Weekday değerleri dizisi
        var days: [Int] {
            switch self {
            case .daily:
                return [1, 2, 3, 4, 5, 6, 7] // Tüm günler
            case .weekdays:
                return [2, 3, 4, 5, 6] // Pazartesi-Cuma
            case .weekends:
                return [1, 7] // Pazar ve Cumartesi
            case .custom:
                return [] // Özel seçim için (henüz implement edilmedi)
            }
        }
    }
    
    // MARK: - Initialization
    /// Private init - sadece singleton instance oluşturulabilir
    /// İlk açılışta kayıtlı ayarları yüklüyor
    private init() {
        loadSettings() // UserDefaults'tan ayarları yükle
    }
    
    // MARK: - Permission Management
    
    /// Kullanıcıdan bildirim izni istiyor
    /// iOS settings'te "Notifications" menüsünü açıyor
    /// İzin verilirse bildirimleri otomatik olarak planlıyor
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // Main thread'de UI güncelleniyor
            DispatchQueue.main.async {
                self.isEnabled = granted
                if granted {
                    // İzin verildiyse bildirimleri planla
                    print("✅ Bildirim izni verildi")
                    self.scheduleNotifications()
                } else {
                    print("❌ Bildirim izni reddedildi")
                }
            }
        }
    }
    
    /// Mevcut bildirim izin durumunu kontrol ediyor
    /// Uygulama açıldığında çağrılarak izin durumu güncelleniyor
    /// Kullanıcı iOS ayarlarından izni iptal etmiş olabilir
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // Authorized durumundaysa isEnabled = true
                self.isEnabled = settings.authorizationStatus == .authorized
                print("🔔 Bildirim izin durumu: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Tüm hatırlatıcı bildirimlerini planlıyor
    /// Önce mevcut bildirimleri iptal edip yenilerini ekliyor
    /// Kullanıcının seçtiği saat ve frekansa göre tekrarlayan bildirimler oluşturuyor
    func scheduleNotifications() {
        // Önce tüm mevcut bildirimleri temizle
        cancelAllNotifications()
        
        // Eğer hatırlatıcılar kapalıysa işlem yapma
        guard isEnabled else { return }
        
        // Bildirim içeriğini hazırla
        let content = UNMutableNotificationContent()
        content.title = "Günlük Zamanı! 📔"
        content.sound = .default
        content.badge = 1 // App icon'da kırmızı badge göster
        
        // Motivasyon sözü veya standart mesaj ekle
        if motivationalQuotesEnabled {
            // Rastgele bir motivasyon sözü seç
            content.body = motivationalQuotes.randomElement() ?? "Bugün nasıl hissediyorsun?"
        } else {
            // Standart mesaj göster
            content.body = "Bugün nasıl hissediyorsun? Duygularını kaydetmeyi unutma."
        }
        
        // Kullanıcının seçtiği saatten hour ve minute bilgilerini al
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        // Seçilen frekansa göre hangi günlerde bildirim gönderileceğini belirle
        let days = reminderFrequency.days
        
        // Her gün için ayrı bir bildirim oluştur
        for day in days {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour     // Kullanıcının seçtiği saat
            dateComponents.minute = components.minute // Kullanıcının seçtiği dakika
            dateComponents.weekday = day              // Haftanın günü (1-7)
            
            // Takvim bazlı trigger oluştur (her hafta tekrar ediyor)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Her gün için unique identifier ile bildirim request'i oluştur
            let request = UNNotificationRequest(
                identifier: "moodReminder_\(day)", // Örnek: moodReminder_1, moodReminder_2, vb.
                content: content,
                trigger: trigger
            )
            
            // Bildirimi sisteme ekle
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Bildirim eklenirken hata: \(error)")
                } else {
                    print("✅ Bildirim başarıyla eklendi: Day \(day)")
                }
            }
        }
        
        // Ayarları UserDefaults'a kaydet
        saveSettings()
    }
    
   
    
    // MARK: - Notification Management
    
    /// Tüm bekleyen bildirimleri iptal ediyor
    /// Kullanıcı hatırlatıcıları kapattığında veya yeni ayarlar yapıldığında çağrılıyor
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ Tüm bildirimler iptal edildi")
    }
    
    /// Uygulama badge sayısını sıfırlıyor
    /// Kullanıcı uygulamayı açtığında badge temizleniyor
    /// App icon'daki kırmızı sayı kalkmış oluyor
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
        print("🧹 Badge temizlendi")
    }
    
    // MARK: - Settings Persistence
    
    /// Tüm hatırlatıcı ayarlarını UserDefaults'a kaydediyor
    /// Uygulama kapatılıp açıldığında ayarlar korunuyor
    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(selectedTime.timeIntervalSince1970, forKey: "reminderTime")
        UserDefaults.standard.set(motivationalQuotesEnabled, forKey: "motivationalQuotes")
        UserDefaults.standard.set(reminderFrequency.rawValue, forKey: "reminderFrequency")
        print("💾 Bildirim ayarları kaydedildi")
    }
    
    /// UserDefaults'tan kayıtlı ayarları yüklüyor
    /// Uygulama ilk açıldığında init içinde çağrılıyor
    private func loadSettings() {
        // Bildirimlerin açık/kapalı durumunu yükle
        isEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        // Kayıtlı hatırlatma saatini yükle
        let timeInterval = UserDefaults.standard.double(forKey: "reminderTime")
        if timeInterval > 0 {
            // Kayıtlı saat varsa onu kullan
            selectedTime = Date(timeIntervalSince1970: timeInterval)
        } else {
            // Kayıtlı saat yoksa default olarak akşam 20:00
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            selectedTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Motivasyon sözlerinin açık/kapalı durumunu yükle (default: true)
        motivationalQuotesEnabled = UserDefaults.standard.bool(forKey: "motivationalQuotes")
        
        // Hatırlatıcı frekansını yükle (default: daily)
        if let frequencyRaw = UserDefaults.standard.string(forKey: "reminderFrequency"),
           let frequency = ReminderFrequency(rawValue: frequencyRaw) {
            reminderFrequency = frequency
        }
        
        print("📥 Bildirim ayarları yüklendi")
    }
}

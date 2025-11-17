//
//  StorageService.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 06.11.2025.
//
//  Core Data ile entry'leri kaydeden, yükleyen ve yöneten servis
//  Tüm veritabanı işlemleri bu class üzerinden yapılıyor
//

import Foundation
import CoreData

// MARK: - Storage Service
/// Core Data yönetimini sağlayan singleton class
/// Entry'leri kaydetme, güncelleme, silme ve sorgulama işlemleri
class StorageService {
    // Singleton instance - uygulama boyunca tek bir StorageService var
    static let shared = StorageService()
    
    // Private init - sadece singleton kullanılabilir
    private init() {}
    
    // MARK: - Core Data Stack
    
    /// Core Data container
    /// "AIMoodJournal.xcdatamodeld" dosyasını kullanıyor
    private let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AIMoodJournal")
        // Veritabanını yükle
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data yüklenemedi: \(error)")
            } else {
                print("✅ Core Data yüklendi!")
            }
        }
        return container
    }()
    
    /// Main context - tüm veritabanı işlemleri bu context üzerinden
    private var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Save Entry
    
    /// Yeni bir entry kaydet
    /// HomeView'da analiz sonrası çağrılıyor
    /// - Parameter entry: Kaydedilecek MoodEntry
    func saveEntry(_ entry: MoodEntry) {
        // Core Data entity oluştur
        let entity = MoodEntryEntity(context: context)
        
        // Model'den Entity'ye veri aktar
        entity.id = entry.id
        entity.date = entry.date
        entity.text = entry.text
        entity.moodType = entry.moodData?.mood.rawValue
        entity.energy = entry.moodData?.energy ?? 0
        entity.sentiment = entry.moodData?.sentiment ?? 0
        entity.keywords = (entry.moodData?.keywords ?? []) as NSObject
        entity.aiSummary = entry.moodData?.aiSummary
        
        // Context'i kaydet
        saveContext()
        
        print("💾 Entry kaydedildi: \(entry.date)")
    }
    
    /// Tüm entry'leri yükle
    /// Deprecated - fetchAllEntries() kullan
    func loadEntries() -> [MoodEntry] {
        return fetchAllEntries()
    }
    
    // MARK: - Fetch Entries
    
    /// Tüm entry'leri getir (tarih sıralı - yeniden eskiye)
    /// StatisticsView ve CalendarView bu fonksiyonu kullanıyor
    /// - Returns: Tüm entry'lerin listesi
    func fetchAllEntries() -> [MoodEntry] {
        let request: NSFetchRequest<MoodEntryEntity> = MoodEntryEntity.fetchRequest()
        
        // Tarihe göre sırala (yeniden eskiye)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            // Core Data'dan çek
            let entities = try context.fetch(request)
            
            // Entity'leri MoodEntry'ye çevir
            return entities.compactMap { entity in
                convertToMoodEntry(entity)
            }
        } catch {
            print("❌ Entry'ler getirilemedi: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Entries by Month
    
    /// Belirli bir aydaki entry'leri getir
    /// CalendarView'da kullanılıyor - her ay için ayrı entry'leri gösteriyor
    /// - Parameter date: Hangi ayın entry'leri isteniyor
    /// - Returns: O aydaki tüm entry'ler
    func fetchEntries(forMonth date: Date) -> [MoodEntry] {
        // Ayın başı ve sonu
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }
        
        let request: NSFetchRequest<MoodEntryEntity> = MoodEntryEntity.fetchRequest()
        
        // Tarih aralığı filtresi (ayın ilk günü ile son günü arası)
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", monthStart as NSDate, monthEnd as NSDate)
        
        // Tarihe göre sırala (eskiden yeniye)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { convertToMoodEntry($0) }
        } catch {
            print("❌ Aylık entry'ler getirilemedi: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Entry by Date
    
    /// Belirli bir tarihteki entry'yi getir
    /// HomeView'da bugünün entry'sini kontrol ederken kullanılıyor
    /// - Parameter date: Hangi günün entry'si isteniyor
    /// - Returns: O günün entry'si (varsa)
    func fetchEntry(forDate date: Date) -> MoodEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let request: NSFetchRequest<MoodEntryEntity> = MoodEntryEntity.fetchRequest()
        // O günün başlangıcı ile bitişi arası (00:00 - 23:59)
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1 // Sadece bir tane dönmesi yeterli
        
        do {
            let entities = try context.fetch(request)
            return entities.first.flatMap { convertToMoodEntry($0) }
        } catch {
            print("❌ Günlük entry getirilemedi: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Entry
    
    /// Entry sil
    /// Kullanıcı entry'yi silmek istediğinde çağrılıyor
    /// - Parameter entry: Silinecek entry
    func deleteEntry(_ entry: MoodEntry) {
        let request: NSFetchRequest<MoodEntryEntity> = MoodEntryEntity.fetchRequest()
        // ID'ye göre bul
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity) // Entity'yi sil
                saveContext() // Değişiklikleri kaydet
                print("🗑️ Entry silindi: \(entry.date)")
            }
        } catch {
            print("❌ Entry silinemedi: \(error)")
        }
    }
    
    // MARK: - Update Entry
    
    /// Mevcut bir entry'yi güncelle
    /// HomeView'da bugünkü entry tekrar analiz edilince çağrılıyor
    /// - Parameter entry: Güncellenmiş entry
    func updateEntry(_ entry: MoodEntry) {
        let request: NSFetchRequest<MoodEntryEntity> = MoodEntryEntity.fetchRequest()
        // ID'ye göre bul
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                print("🔍 Güncellenecek entity bulundu!")
                print("🔍 Eski metin: \(entity.text ?? "nil")")
                print("🔍 Yeni metin: \(entry.text)")
                
                // Entity'nin değerlerini güncelle
                entity.text = entry.text
                entity.moodType = entry.moodData?.mood.rawValue
                entity.energy = entry.moodData?.energy ?? 0
                entity.sentiment = entry.moodData?.sentiment ?? 0
                entity.keywords = (entry.moodData?.keywords ?? []) as NSObject
                entity.aiSummary = entry.moodData?.aiSummary
                
                // Değişiklikleri kaydet
                try context.save()
                print("💾 Core Data save() çağrıldı!")
                
                // Kontrol amaçlı - güncelleme başarılı mı?
                let checkRequest: NSFetchRequest<MoodEntryEntity> = MoodEntryEntity.fetchRequest()
                checkRequest.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
                checkRequest.fetchLimit = 1
                let checkEntities = try context.fetch(checkRequest)
                if let checkEntity = checkEntities.first {
                    print("🔍 KONTROL: Kaydedilen metin: \(checkEntity.text ?? "nil")")
                }
                
                print("✏️ Entry güncellendi: \(entry.date)")
            } else {
                print("❌ Güncellenecek entity bulunamadı! ID: \(entry.id)")
            }
        } catch {
            print("❌ Entry güncellenemedi: \(error)")
        }
    }
    
    // MARK: - Clean Duplicate Entries
    
    /// Aynı güne ait birden fazla entry varsa sadece en yenisini tut
    /// Günde 1 entry sistemi için - duplicate entry'leri temizliyor
    /// Uygulama ilk açılışta çağrılıyor (HomeView.onAppear)
    func cleanDuplicateEntries() {
        let entries = fetchAllEntries()
        let calendar = Calendar.current
        
        // Tarihe göre grupla
        var entriesByDate: [Date: [MoodEntry]] = [:]
        
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            if entriesByDate[day] == nil {
                entriesByDate[day] = []
            }
            entriesByDate[day]?.append(entry)
        }
        
        // Her gün için sadece EN SON entry'yi tut, geri kalanları sil
        for (day, dayEntries) in entriesByDate {
            if dayEntries.count > 1 {
                print("🗑️ \(day) için \(dayEntries.count) entry bulundu, en son olanı hariç silinecek")
                
                // Tarihe göre sırala, en yeni olan başta
                let sorted = dayEntries.sorted { $0.date > $1.date }
                
                // İlki (en yeni) hariç hepsini sil
                for i in 1..<sorted.count {
                    deleteEntry(sorted[i])
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Context'teki değişiklikleri Core Data'ya kaydet
    private func saveContext() {
        // Değişiklik var mı kontrol et
        if context.hasChanges {
            do {
                try context.save()
                print("💾 Core Data kaydedildi!")
            } catch {
                print("❌ Context kaydedilemedi: \(error)")
            }
        } else {
            print("⚠️ Kaydedilecek değişiklik yok!")
        }
    }
    
    /// Core Data Entity'yi MoodEntry modeline çevir
    /// Core Data'dan aldığımız veriyi uygulamamızın kullandığı modele dönüştürüyor
    /// - Parameter entity: Core Data entity
    /// - Returns: MoodEntry modeli
    private func convertToMoodEntry(_ entity: MoodEntryEntity) -> MoodEntry? {
        // Gerekli alanlar var mı kontrol et
        guard let id = entity.id,
              let date = entity.date,
              let text = entity.text else {
            return nil
        }
        
        // MoodData oluştur (eğer analiz yapılmışsa)
        var moodData: MoodData?
        if let moodTypeString = entity.moodType,
           let moodType = MoodType(rawValue: moodTypeString) {
            
            let keywords = entity.keywords as? [String] ?? []
            
            moodData = MoodData(
                mood: moodType,
                energy: entity.energy,
                sentiment: entity.sentiment,
                keywords: keywords,
                aiSummary: entity.aiSummary ?? ""
            )
        }
        
        // MoodEntry oluştur ve döndür
        return MoodEntry(
            id: id,
            date: date,
            text: text,
            moodData: moodData,
            artworkColors: nil
        )
    }
}

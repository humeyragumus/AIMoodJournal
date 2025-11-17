//
//  StatisticsView.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 07.11.2025.
//
//  İstatistikler ve grafikler ekranı
//  Ruh hali trendlerini, dağılımını ve analizlerini gösteriyor
//

import SwiftUI
import Charts

struct StatisticsView: View {
    // Zaman periyodu seçimi (hafta, ay, yıl)
    @State private var selectedPeriod: TimePeriod = .week
    
    // Günlük entry'ler
    @State var entries: [MoodEntry] = []
    
    // Yükleme durumu
    @State private var isLoading: Bool = true
    
    // İstatistik verileri - hesaplanmış değerler
    @State private var moodTrends: [MoodTrendData] = []
    @State private var moodDistribution: [MoodDistributionData] = []
    @State private var topKeywords: [KeywordData] = []
    @State private var averageEnergy: Double = 0.0
    @State private var averageSentiment: Double = 0.0
    
    var body: some View {
        ZStack {
            // Arka plan
            AppColors.background
                .ignoresSafeArea()
            
            if isLoading {
                // Veriler yüklenirken loading göster
                ProgressView()
                    .tint(AppColors.primary)
                    .scaleEffect(1.5)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Başlık bölümü
                        headerSection
                        
                        // Zaman periyodu seçici (Hafta/Ay/Yıl)
                        periodSelector
                        
                        // Ruh hali trendi grafiği
                        moodTrendSection
                        
                        // İstatistik kartları (en iyi gün, aktif gün, seri)
                        statsCardsSection
                        
                        // Duygu dağılımı
                        moodDistributionSection
                        
                        // En çok kullanılan kelimeler
                        keywordsSection
                        
                        // Enerji ve duygu tonu göstergeleri
                        energySentimentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            // Sayfa açılınca verileri yükle
            loadData()
        }
    }
    
    // MARK: - Header
    // Başlık bölümü
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İstatistikler")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Ruh hali analizlerin")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
    
    // MARK: - Period Selector
    // Hafta/Ay/Yıl seçim butonları
    private var periodSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                PeriodButton(
                    title: period.title,
                    isSelected: selectedPeriod == period,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                            loadData() // Periyot değişince verileri yeniden yükle
                        }
                    }
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
    
    // MARK: - Mood Trend Chart
    // Ruh hali trendini gösteren çizgi grafiği
    private var moodTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ruh Hali Trendi")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            if !moodTrends.isEmpty {
                // Swift Charts ile grafik oluşturuyorum
                Chart(moodTrends) { data in
                    // Çizgi grafiği
                    LineMark(
                        x: .value("Tarih", data.date),
                        y: .value("Mood", data.moodScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .interpolationMethod(.catmullRom) // Yumuşak eğri
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    // Alan grafiği (çizginin altını doldur)
                    AreaMark(
                        x: .value("Tarih", data.date),
                        y: .value("Mood", data.moodScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.3),
                                AppColors.secondary.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    // Nokta işaretleri
                    PointMark(
                        x: .value("Tarih", data.date),
                        y: .value("Mood", data.moodScore)
                    )
                    .foregroundStyle(AppColors.primary)
                    .symbolSize(60)
                }
                .frame(height: 200)
                .chartXAxis {
                    // X ekseni (tarihler)
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel(
                            format: .dateTime.weekday(.abbreviated),
                            centered: true
                        )
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    // Y ekseni (ruh hali skoru)
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .chartYScale(domain: 0...5) // Skor aralığı 0-5
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                )
            } else {
                // Veri yoksa bilgilendirme göster
                NoDataView(message: "Henüz yeterli veri yok")
            }
        }
    }
    
    // MARK: - Stats Cards
    // Üç adet istatistik kartı
    private var statsCardsSection: some View {
        HStack(spacing: 12) {
            // En iyi gün (en yüksek ruh hali)
            StatCard(
                icon: "face.smiling.fill",
                title: "En İyi Gün",
                value: getBestDay(),
                color: AppColors.moodGreen
            )
            
            // Toplam aktif gün sayısı
            StatCard(
                icon: "calendar",
                title: "Aktif Gün",
                value: "\(getUniqueDaysCount())",
                color: AppColors.moodBlue
            )
            
            // Ardışık gün serisi
            StatCard(
                icon: "flame.fill",
                title: "Seri",
                value: "\(getCurrentStreak())",
                color: AppColors.moodPeach
            )
        }
    }
    
    
    // MARK: - Mood Distribution
    // Hangi ruh halinden kaç tane olduğunu gösteren bölüm
    private var moodDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duygu Dağılımı")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            if !moodDistribution.isEmpty {
                VStack(spacing: 12) {
                    ForEach(moodDistribution) { data in
                        MoodBar(data: data) // Her ruh hali için progress bar
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                )
            } else {
                NoDataView(message: "Henüz veri yok")
            }
        }
    }
    
    // MARK: - Keywords Section
    // Günlüklerde en çok kullanılan kelimeler
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("En Çok Kullanılan Kelimeler")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            if !topKeywords.isEmpty {
                // FlowLayout ile kelimeleri yan yana diziyorum
                FlowLayout(spacing: 8) {
                    ForEach(topKeywords) { keyword in
                        KeywordChip(keyword: keyword)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                )
            } else {
                NoDataView(message: "Henüz kelime analizi yok")
            }
        }
    }
    
    // MARK: - Energy & Sentiment
    // Ortalama enerji ve duygu tonu dairesel göstergeleri
    private var energySentimentSection: some View {
        HStack(spacing: 16) {
            // Enerji göstergesi
            GaugeCard(
                title: "Ortalama Enerji",
                value: averageEnergy,
                icon: "bolt.fill",
                color: AppColors.moodYellow
            )
            
            // Duygu tonu göstergesi
            GaugeCard(
                title: "Duygu Tonu",
                value: (averageSentiment + 1) / 2, // -1,1 aralığını 0,1'e çeviriyorum
                icon: "heart.fill",
                color: AppColors.moodPink
            )
        }
    }
    
    // MARK: - Helper Functions
    
    // Verileri yükleme fonksiyonu
    private func loadData() {
        isLoading = true
        
        // Kısa gecikme ile (animasyon için)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Tüm entry'leri getir
            let allEntries = StorageService.shared.fetchAllEntries()
            
            // Seçili periyoda göre filtrele
            self.entries = filterEntriesByPeriod(allEntries)
            
            // Tüm istatistikleri hesapla
            calculateMoodTrends()
            calculateMoodDistribution()
            calculateTopKeywords()
            calculateAverages()
            
            withAnimation {
                isLoading = false
            }
        }
    }
    
    // Seçili zaman periyoduna göre entry'leri filtrele
    private func filterEntriesByPeriod(_ allEntries: [MoodEntry]) -> [MoodEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            // Son 7 günü getir
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return allEntries.filter { $0.date >= weekAgo }
        case .month:
            // Son 1 ayı getir
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return allEntries.filter { $0.date >= monthAgo }
        case .year:
            // Son 1 yılı getir
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return allEntries.filter { $0.date >= yearAgo }
        }
    }
    
    // Grafik için ruh hali trendlerini hesapla
    private func calculateMoodTrends() {
        moodTrends = entries.compactMap { entry in
            guard let moodData = entry.moodData else { return nil }
            let score = getMoodScore(for: moodData.mood)
            return MoodTrendData(date: entry.date, moodScore: score)
        }.sorted { $0.date < $1.date } // Tarihe göre sırala
    }
    
    // Ruh hali dağılımını hesapla (hangi ruh halinden kaç tane)
    private func calculateMoodDistribution() {
        var distribution: [MoodType: Int] = [:]
        
        // Her ruh halini say
        for entry in entries {
            if let mood = entry.moodData?.mood {
                distribution[mood, default: 0] += 1
            }
        }
        
        // Yüzdelik oranları hesapla ve sırala
        moodDistribution = distribution.map { mood, count in
            MoodDistributionData(
                mood: mood,
                count: count,
                percentage: Double(count) / Double(entries.count)
            )
        }.sorted { $0.count > $1.count } // En çoktan aza sırala
    }
    
    // En çok kullanılan kelimeleri hesapla
    private func calculateTopKeywords() {
        var keywordCounts: [String: Int] = [:]
        
        // Tüm kelimeleri say
        for entry in entries {
            if let keywords = entry.moodData?.keywords {
                for keyword in keywords {
                    keywordCounts[keyword, default: 0] += 1
                }
            }
        }
        
        // En çok kullanılan 10 kelimeyi al
        topKeywords = keywordCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { KeywordData(word: $0.key, count: $0.value) }
    }
    
    // Ortalama enerji ve duygu tonunu hesapla
    private func calculateAverages() {
        let energies = entries.compactMap { $0.moodData?.energy }
        averageEnergy = energies.isEmpty ? 0 : energies.reduce(0, +) / Double(energies.count)
        
        let sentiments = entries.compactMap { $0.moodData?.sentiment }
        averageSentiment = sentiments.isEmpty ? 0 : sentiments.reduce(0, +) / Double(sentiments.count)
    }
    
    // Ruh halini 0-5 arası skora çevir (grafik için)
    private func getMoodScore(for mood: MoodType) -> Double {
        switch mood {
        case .excited: return 5.0
        case .happy: return 4.0
        case .energetic: return 3.5
        case .peaceful: return 3.0
        case .calm: return 2.5
        case .neutral: return 2.0
        case .anxious: return 1.5
        case .sad: return 1.0
        }
    }
    
    // En iyi günü bul (en yüksek ruh hali skoru)
    private func getBestDay() -> String {
           guard let bestEntry = entries.max(by: {
               getMoodScore(for: $0.moodData?.mood ?? .neutral) <
               getMoodScore(for: $1.moodData?.mood ?? .neutral)
           }) else { return "-" }
           
           let formatter = DateFormatter()
           formatter.dateFormat = "EEEE"
           formatter.locale = Locale(identifier: "tr_TR")
           return formatter.string(from: bestEntry.date)
       }
    
    // Ardışık gün serisini hesapla
    private func getCurrentStreak() -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }
        
        // Tekrar eden günleri temizle, sadece unique günler
        let uniqueDays = Set(sortedEntries.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted(by: >)
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Bugünden geriye doğru say
        for day in sortedDays {
            // Bugün veya bir önceki gün mü?
            if calendar.isDate(day, inSameDayAs: currentDate) ||
               calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                streak += 1
                currentDate = day
            } else {
                // Seri kırıldı
                break
            }
        }
        
        print("🔥 Seri: \(streak) gün")
        return streak
    }
    
    // Toplam aktif gün sayısı
    private func getUniqueDaysCount() -> Int {
        // Unique günleri say
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
}



// MARK: - Supporting Types
enum TimePeriod: String, CaseIterable {
    case week = "Hafta"
    case month = "Ay"
    case year = "Yıl"
    
    var title: String { rawValue }
}

// MARK: - Data Models
struct MoodTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let moodScore: Double
}

struct MoodDistributionData: Identifiable {
    let id = UUID()
    let mood: MoodType
    let count: Int
    let percentage: Double
}

struct KeywordData: Identifiable {
    let id = UUID()
    let word: String
    let count: Int
}

// MARK: - Components
struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AppColors.primary : .clear)
                )
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
        )
    }
}

struct MoodBar: View {
    let data: MoodDistributionData
    
    var body: some View {
        HStack(spacing: 12) {
            Text(data.mood.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(data.mood.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.getDominantColor(for: data.mood))
                            .frame(width: geometry.size.width * data.percentage)
                    }
                }
                .frame(height: 8)
            }
            
            Text("\(data.count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct KeywordChip: View {
    let keyword: KeywordData
    
    var body: some View {
        HStack(spacing: 4) {
            Text(keyword.word)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Text("(\(keyword.count))")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppColors.primary.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct GaugeCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.spring(response: 0.5), value: value)
                
                Text("\(Int(value * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
        )
    }
}

struct NoDataView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
        )
    }
}

#Preview {
    StatisticsView()
}

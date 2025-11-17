//
//  CalendarView.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 04.11.2025.
//
//  Aylık takvim görünümü
//  Geçmiş günlük entry'lerini takvim formatında gösteriyor
//

import SwiftUI

struct CalendarView: View {
    // Şu an görüntülenen ay
    @State var currentMonth: Date = Date()
    
    // O aydaki tüm entry'ler
    @State var entries: [MoodEntry] = []
    
    // Tıklanan entry
    @State var selectedEntry: MoodEntry?
    
    // Detay modalı
    @State var showEntryDetail: Bool = false
    
    // Takvim işlemleri için
    let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            // Arka plan
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Üst kısım - ay seçici (◀ Kasım 2025 ▶)
                monthHeader
                
                // Haftanın günleri (P S Ç P C C P)
                weekdayHeader
                
                // Takvim grid'i
                ScrollView(showsIndicators: false) {
                    calendarGrid
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                }
            }
        }
        .onAppear {
            // İlk açılışta entry'leri yükle
            loadEntries()
        }
        .onChange(of: currentMonth) { oldValue, newValue in
            // Ay değişince entry'leri yeniden yükle
            loadEntries()
        }
        .onChange(of: showEntryDetail) { oldValue, newValue in
            // Detay modalı kapandığında entry'leri yenile
            if !newValue {
                loadEntries()
            }
        }
        .sheet(isPresented: $showEntryDetail) {
            // Entry detay modalı
            if let entry = selectedEntry {
                EntryDetailSheet(entry: entry)
            }
        }
    }
    
    // MARK: - Month Header
    // Ay seçici bölümü (◀ Kasım 2025 ▶)
    var monthHeader: some View {
        HStack {
            // Önceki ay butonu
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Ay ve yıl + kayıt sayısı
            VStack(spacing: 4) {
                Text(monthYearString)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(entries.count) kayıt")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Sonraki ay butonu (gelecek aylara gidemezsin)
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
            }
            .disabled(isCurrentOrFutureMonth) // Bugünün ayındaysan sonraki aya gidemezsin
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    
    // MARK: - Weekday Header
    // Haftanın günlerini gösteren başlık (P S Ç P C C P)
    var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Calendar Grid
    // Takvim hücreleri (7x5 veya 7x6 grid)
    var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    // Gün hücresi
                    DayCell(
                        date: date,
                        entry: getEntry(for: date), // O günün entry'si var mı?
                        isToday: calendar.isDateInToday(date), // Bugün mü?
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) // Bu ayda mı?
                    )
                    .onTapGesture {
                        // Hücreye tıklanınca detayı göster
                        if let entry = getEntry(for: date) {
                            selectedEntry = entry
                            showEntryDetail = true
                        }
                    }
                } else {
                    // Boş hücre (önceki/sonraki ayın günleri için)
                    Color.clear
                        .frame(height: 70)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Seçili aydaki entry'leri yükle
    func loadEntries() {
        entries = StorageService.shared.fetchEntries(forMonth: currentMonth)
        print("📅 \(entries.count) entry yüklendi")
    }
    
    // Belirli bir tarihin entry'sini bul
    func getEntry(for date: Date) -> MoodEntry? {
        return entries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    // Önceki aya geç
    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    // Sonraki aya geç (gelecek aya gidemez)
    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth),
           newMonth <= Date() {
            currentMonth = newMonth
        }
    }
    
    // MARK: - Computed Properties
    
    // "Kasım 2025" formatında ay adı
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: currentMonth)
    }
    
    // Haftanın günlerinin kısaltmaları (P, S, Ç, P, C, C, P)
    var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.shortWeekdaySymbols.map { String($0.prefix(1)) }
    }
    
    // Takvim grid'i için günlerin dizisi
    var daysInMonth: [Date?] {
        // Ayın ilk günü
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        
        // İlk gün hangi gün? (Pazartesi başlangıç için ayarlama)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offsetDays = (firstWeekday + 5) % 7 // Pazartesi başlangıç için offset
        
        // Başta boş hücreler ekle
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        // Ayın günlerini ekle
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // Şu an görüntülenen ay bugün veya gelecekte mi?
    var isCurrentOrFutureMonth: Bool {
        let comparison = calendar.compare(currentMonth, to: Date(), toGranularity: .month)
        return comparison == .orderedSame || comparison == .orderedDescending
    }
}

// MARK: - Day Cell Component
// Takvimde her bir gün için hücre
struct DayCell: View {
    let date: Date
    let entry: MoodEntry? // O günün entry'si
    let isToday: Bool // Bugün mü?
    let isCurrentMonth: Bool // Bu ayda mı?
    
    let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 6) {
            // Gün numarası (1, 2, 3, ...)
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundColor(textColor)
            
            // Ruh hali göstergesi (küçük renkli nokta)
            if let entry = entry, let moodData = entry.moodData {
                // Entry varsa ruh haline göre renkli nokta
                Circle()
                    .fill(AppColors.getDominantColor(for: moodData.mood))
                    .frame(width: 8, height: 8)
            } else {
                // Entry yoksa boş çember
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isToday ? 2 : 1)
                )
        )
        .opacity(isCurrentMonth ? 1.0 : 0.5) // Başka ayın günleri soluk
    }
    
    // Metin rengi
    var textColor: Color {
        if !isCurrentMonth {
            return .white.opacity(0.3)
        }
        return .white.opacity(0.9)
    }
    
    // Arka plan rengi
    var backgroundColor: Color {
        if entry != nil {
            return .white.opacity(0.1) // Entry varsa biraz daha belirgin
        }
        return .white.opacity(0.05)
    }
    
    // Çerçeve rengi
    var borderColor: Color {
        if isToday {
            return AppColors.primary // Bugünse primary renk
        }
        if entry != nil {
            return .white.opacity(0.2) // Entry varsa hafif çerçeve
        }
        return .white.opacity(0.1)
    }
}

// MARK: - Entry Detail Sheet
// Gün detayını gösteren modal
struct EntryDetailSheet: View {
    let entry: MoodEntry
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Tarih
                    Text(entry.formattedDate)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 40)
                    
                    // Ruh hali
                    if let moodData = entry.moodData {
                        VStack(spacing: 16) {
                            // Büyük emoji
                            Text(moodData.mood.emoji)
                                .font(.system(size: 80))
                            
                            // Ruh hali adı
                            Text(moodData.mood.rawValue)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Günlük metni
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Günlük")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(entry.text)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.05))
                        )
                        
                        // AI Özeti
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Analizi")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(moodData.aiSummary)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.05))
                        )
                    }
                    
                    // Kapat butonu
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                    .padding(.top, 20)
                }
                .padding(24)
            }
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

//
//  MoodResultSheet.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 09.11.2025.
//
//  AI analiz sonuçlarını gösteren modal ekran
//  Ruh hali, enerji seviyesi, duygu tonu ve AI önerileri
//

import SwiftUI

struct MoodResultSheet: View {
    let moodData: MoodData      // AI'dan gelen analiz sonuçları
    let journalText: String     // Kullanıcının yazdığı orijinal metin
    
    @Environment(\.dismiss) var dismiss  // Modal'ı kapatmak için
    
    // AI önerileri (aktiviteler, egzersizler, vs.)
    @State private var suggestions: [SuggestionEngine.Suggestion] = []
    @State private var selectedSuggestion: SuggestionEngine.Suggestion?
    
    // MoodData'dan direkt erişim için kolaylık propertyleri
    private var mood: MoodType { moodData.mood }
    private var energy: Double { moodData.energy * 10 } // 0-1'den 0-10'a çeviriyorum
    private var sentiment: Double { moodData.sentiment }
    private var summary: String { moodData.aiSummary }
    private var keywords: [String] { moodData.keywords }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan - koyu kahverengi
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Ruh hali ikonu (büyük emoji)
                        moodIconSection
                        
                        // Enerji ve duygu tonu bilgileri
                        moodInfoCard
                        
                        // AI özeti
                        summaryCard
                        
                        // Anahtar kelimeler (varsa)
                        if !keywords.isEmpty {
                            keywordsCard
                        }
                        
                        // AI önerileri - ruh haline göre aktivite önerileri
                        suggestionsSection
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Sağ üst - Kapat butonu
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
                
                // Orta - Başlık
                ToolbarItem(placement: .principal) {
                    Text("Analiz Sonucu")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .onAppear {
            // Modal açılınca ruh haline göre öneriler oluştur
            suggestions = SuggestionEngine.shared.generateSuggestions(
                mood: mood,
                energy: energy,
                sentiment: sentiment
            )
        }
    }
    
    // MARK: - Mood Icon Section
    // Ortada büyük ruh hali emoji'si
    private var moodIconSection: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                // Arka planda ışıltılı glow efekti
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.getDominantColor(for: mood).opacity(0.3),
                                AppColors.getDominantColor(for: mood).opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                // İkon arka planı
                Circle()
                    .fill(AppColors.surface)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
                
                // Ruh hali emoji'si
                Text(mood.emoji)
                    .font(.system(size: 60))
            }
            
            // Ruh hali adı (örn: "Mutlu", "Sakin", vs.)
            Text(mood.name)
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    // MARK: - Mood Info Card
    // Enerji seviyesi ve duygu tonu göstergeleri
    private var moodInfoCard: some View {
        VStack(spacing: AppSpacing.md) {
            // Enerji seviyesi (0-10)
            HStack {
                Label("Enerji Seviyesi", systemImage: "bolt.fill")
                    .foregroundColor(AppColors.textPrimary)
                    .font(AppFonts.body)
                
                Spacer()
                
                Text(String(format: "%.0f/10", energy))
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
            }
            
            // Enerji progress bar'ı
            ProgressView(value: energy / 10)
                .tint(AppColors.primary)
            
            Divider()
                .background(AppColors.textTertiary)
            
            // Duygu tonu (pozitif/negatif)
            HStack {
                Label("Duygu Tonu", systemImage: sentiment > 0 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .foregroundColor(AppColors.textPrimary)
                    .font(AppFonts.body)
                
                Spacer()
                
                Text(getSentimentText(sentiment))
                    .font(AppFonts.headline)
                    .foregroundColor(getSentimentColor(sentiment))
            }
            
            // Duygu tonu progress bar'ı
            ProgressView(value: (sentiment + 1) / 2) // -1,1 aralığını 0,1'e çeviriyorum
                .tint(getSentimentColor(sentiment))
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - Summary Card
    // AI'ın yazdığı özet
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.primary)
                Text("AI Özeti")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(summary)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - Keywords Card
    // Metinden çıkarılan anahtar kelimeler
    private var keywordsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(AppColors.accent)
                Text("Anahtar Kelimeler")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Kelimeleri yan yana akışkan düzende göster
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(AppColors.surfaceLight)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - Suggestions Section
    // Ruh haline göre AI'ın önerdiği aktiviteler
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppColors.moodYellow)
                Text("Size Özel Öneriler")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            if suggestions.isEmpty {
                // Öneriler henüz yüklenmediyse
                Text("Öneriler yükleniyor...")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.lg)
            } else {
                // Öneri kartlarını göster
                VStack(spacing: AppSpacing.sm) {
                    ForEach(suggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion)
                            .onTapGesture {
                                selectedSuggestion = suggestion // Detay modalını aç
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
        .sheet(item: $selectedSuggestion) { suggestion in
            // Öneri detay modalı
            SuggestionDetailView(suggestion: suggestion)
        }
    }
    
    // MARK: - Helper Functions
    // Duygu tonunu metne çeviriyorum
    private func getSentimentText(_ value: Double) -> String {
        if value > 0.5 {
            return "Çok Pozitif"
        } else if value > 0.1 {
            return "Pozitif"
        } else if value > -0.1 {
            return "Nötr"
        } else if value > -0.5 {
            return "Negatif"
        } else {
            return "Çok Negatif"
        }
    }
    
    // Duygu tonuna göre renk belirliyorum
    private func getSentimentColor(_ value: Double) -> Color {
        if value > 0 {
            return AppColors.moodGreen // Pozitif = yeşil
        } else if value < 0 {
            return AppColors.moodPink // Negatif = pembe
        } else {
            return AppColors.textSecondary // Nötr = gri
        }
    }
}

// MARK: - Suggestion Card
// Her bir öneri için küçük kart komponenti
struct SuggestionCard: View {
    let suggestion: SuggestionEngine.Suggestion
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Öneri ikonu
            ZStack {
                Circle()
                    .fill(suggestion.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: suggestion.icon)
                    .font(.system(size: 24))
                    .foregroundColor(suggestion.color)
            }
            
            // Öneri metni
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(suggestion.description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Sağ ok
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 14))
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColors.surfaceLight)
        )
    }
}

// MARK: - Suggestion Detail View
// Öneri detaylarını gösteren tam ekran modal
struct SuggestionDetailView: View {
    let suggestion: SuggestionEngine.Suggestion
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.xl) {
                    // Büyük ikon
                    ZStack {
                        Circle()
                            .fill(suggestion.color.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(AppColors.surface)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: suggestion.icon)
                            .font(.system(size: 50))
                            .foregroundColor(suggestion.color)
                    }
                    .padding(.top, AppSpacing.xl)
                    
                    // Başlık
                    Text(suggestion.title)
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Kategori etiketi
                    Text(suggestion.category.rawValue)
                        .font(AppFonts.caption)
                        .foregroundColor(suggestion.color)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(suggestion.color.opacity(0.2))
                        )
                    
                    // Detaylı açıklama
                    Text(suggestion.description)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    Spacer()
                    
                    // Anladım butonu
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Anladım")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
                            )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout
// Anahtar kelimeleri yan yana akışkan düzende yerleştiren layout
// SwiftUI'ın standart layout'larında yok, kendim yazdım
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [CGRect]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var frames: [CGRect] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            // Her elemanı yerleştir, satır dolduğunda alt satıra geç
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: subviewSize))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.frames = frames
        }
    }
}

struct MoodResultSheet_Previews: PreviewProvider {
    static var previews: some View {
        MoodResultSheet(
            moodData: MoodData.example,
            journalText: "Bugün harika bir gündü! Çok mutluyum."
        )
    }
}

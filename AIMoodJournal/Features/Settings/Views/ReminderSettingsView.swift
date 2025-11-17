//
//  ReminderSettingsView.swift
//  AIMoodJournal
//
//  Günlük hatırlatıcı bildirimleri ayarları ekranı
//  Kullanıcı günlük yazmayı unutmaması için hatırlatıcı kurabilir
//

import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    // Bildirim yöneticisi - hatırlatıcıları kontrol ediyor
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Saat seçici modalını göster/gizle
    @State private var showingTimePicker = false
    
    // Test bildirimi gönderilirken gösterge
    @State private var showingTestNotification = false
    
    // Modal'ı kapatmak için
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan - koyu kahverengi
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Üst başlık kartı
                        headerCard
                        
                        // Ana hatırlatıcı açma/kapama
                        mainReminderToggle
                        
                        // Hatırlatıcı açıksa diğer ayarları göster
                        if notificationManager.isEnabled {
                            // Saat seçici
                            timeSelector
                            
                            // Ne sıklıkla hatırlatılsın (her gün, hafta içi, vs.)
                            frequencySelector
                            
                            // Motivasyon sözleri eklensin mi?
                            motivationalQuotesToggle
                            
                            // Test için bildirim gönder
                          
                        }
                        
                        // Kullanım ipuçları
                        tipsSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Sol üst - Kapat butonu
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
                
                // Orta - Başlık
                ToolbarItem(placement: .principal) {
                    Text("Hatırlatıcılar")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .onAppear {
            // Sayfa açılınca bildirim iznini kontrol et
            notificationManager.checkPermission()
        }
    }
    
    // MARK: - Header Card
    // Üst kısımdaki başlık kartı - çan ikonu ile
    private var headerCard: some View {
        VStack(spacing: 12) {
            // Gradient renkli çan ikonu
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10)
            
            Text("Günlük Hatırlatıcıları")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Düzenli yazma alışkanlığı kazanın")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppColors.surface)
                .overlay(
                    // Gradient kenarlık
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.primary.opacity(0.3),
                                    AppColors.accent.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        )
    }
    
    // MARK: - Ana Hatırlatıcı Toggle
    // Hatırlatıcıları açma/kapama anahtarı
    private var mainReminderToggle: some View {
        HStack {
            Label("Hatırlatıcıları Etkinleştir", systemImage: "bell.fill")
                .foregroundColor(AppColors.textPrimary)
                .font(AppFonts.headline)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { notificationManager.isEnabled },
                set: { newValue in
                    if newValue {
                        // Açıldığında izin iste
                        notificationManager.requestPermission()
                    } else {
                        // Kapatıldığında tüm bildirimleri iptal et
                        notificationManager.isEnabled = false
                        notificationManager.cancelAllNotifications()
                    }
                }
            ))
            .labelsHidden()
            .tint(AppColors.primary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - Zaman Seçici
    // Hangi saatte hatırlatılmak istediğini seç
    private var timeSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Hatırlatma Zamanı", systemImage: "clock.fill")
                .foregroundColor(AppColors.textPrimary)
                .font(AppFonts.headline)
            
            Button(action: { showingTimePicker.toggle() }) {
                HStack {
                    // Seçili saati göster
                    Text(timeFormatter.string(from: notificationManager.selectedTime))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.surfaceLight)
                )
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
        .sheet(isPresented: $showingTimePicker) {
            timePickerSheet
        }
    }
    
    // MARK: - Time Picker Sheet
    // Saat seçici modalı
    private var timePickerSheet: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.lg) {
                    // iOS'un tekerlek tarzı saat seçici
                    DatePicker(
                        "Saat Seçin",
                        selection: $notificationManager.selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(AppColors.surface)
                    )
                    .padding(.horizontal)
                    
                    // Kaydet butonu
                    Button("Kaydet") {
                        notificationManager.scheduleNotifications()
                        showingTimePicker = false
                    }
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
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
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Saat Seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        showingTimePicker = false
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Frekans Seçici
    // Ne sıklıkla hatırlatılacak: Her gün, Hafta içi, Hafta sonu
    private var frequencySelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Hatırlatma Sıklığı", systemImage: "calendar")
                .foregroundColor(AppColors.textPrimary)
                .font(AppFonts.headline)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(NotificationManager.ReminderFrequency.allCases, id: \.self) { frequency in
                    if frequency != .custom {
                        Button(action: {
                            notificationManager.reminderFrequency = frequency
                            notificationManager.scheduleNotifications()
                        }) {
                            HStack {
                                // Seçili olanı işaretle
                                Image(systemName: notificationManager.reminderFrequency == frequency ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(notificationManager.reminderFrequency == frequency ? AppColors.primary : AppColors.textTertiary)
                                
                                Text(frequency.rawValue)
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(AppFonts.body)
                                
                                Spacer()
                            }
                            .padding(.vertical, AppSpacing.sm)
                            .padding(.horizontal, AppSpacing.md)
                            .background(
                                // Seçili olan arka planı daha koyu
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(notificationManager.reminderFrequency == frequency ? AppColors.surfaceLight : Color.clear)
                            )
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - Motivasyon Sözleri Toggle
    // Bildirimlerde motivasyon sözleri gösterilsin mi?
    private var motivationalQuotesToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Motivasyon Sözleri", systemImage: "quote.bubble.fill")
                    .foregroundColor(AppColors.textPrimary)
                    .font(AppFonts.headline)
                
                Text("Hatırlatıcılarda ilham verici sözler göster")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $notificationManager.motivationalQuotesEnabled)
                .labelsHidden()
                .tint(AppColors.primary)
                .onChange(of: notificationManager.motivationalQuotesEnabled) { oldValue, newValue in
                    // Değişince bildirimleri yeniden planla
                    notificationManager.scheduleNotifications()
                }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
   
    
    // MARK: - İpuçları
    // Kullanıcı için faydalı ipuçları
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppColors.moodYellow)
                Text("İpuçları")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                tipRow(
                    icon: "moon.fill",
                    text: "Akşam saatlerini tercih edin",
                    color: AppColors.moodPurple
                )
                
                tipRow(
                    icon: "heart.fill",
                    text: "Düzenli yazma alışkanlığı kazanın",
                    color: AppColors.moodPink
                )
                
                tipRow(
                    icon: "sparkles",
                    text: "Kendinize günde 5 dakika ayırın",
                    color: AppColors.moodYellow
                )
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // İpucu satırı komponenti
    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColors.surfaceLight.opacity(0.5))
        )
    }
    
    // Saat formatını Türkçe'ye çeviren formatter
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct ReminderSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderSettingsView()
    }
}

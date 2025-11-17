//
//  SecuritySettingsView.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 14.11.2025.
//
//  Güvenlik ayarları ekranı
//  Face ID / Touch ID kilit ayarlarını yönetiyor
//

import SwiftUI

struct SecuritySettingsView: View {
    // Biyometrik (Face ID/Touch ID) yöneticisi
    @StateObject private var biometricManager = BiometricManager.shared
    
    // Modal'ı kapatmak için
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan - koyu kahverengi
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Üst başlık kartı
                        headerCard
                        
                        // Face ID/Touch ID açma/kapama
                        biometricToggle
                        
                        // Bilgilendirme bölümü
                        infoSection
                        
                        // Test butonu (geliştirme aşamasında kullandığım)
                       
                    }
                    .padding(AppSpacing.md)
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
                    Text("Güvenlik")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Header Card
    // Üst kısımdaki başlık kartı - kilit ikonu ile
    private var headerCard: some View {
        VStack(spacing: AppSpacing.md) {
            // Gradient renkli kilit ikonu
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10)
            
            Text("Günlüklerinizi Koruyun")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Gizliliğiniz bizim için önemli")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
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
    
    // MARK: - Biometric Toggle
    // Face ID/Touch ID açma/kapama anahtarı
    private var biometricToggle: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                // Cihazın biyometrik tipine göre ikon (Face ID veya Touch ID)
                Image(systemName: biometricManager.biometricType.icon)
                    .foregroundColor(AppColors.primary)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(biometricManager.biometricType.name) Kilidi")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Cihazda biyometrik varsa açıklama göster
                    Text(biometricManager.biometricType == .none ?
                         "Cihazınızda biyometrik doğrulama yok" :
                         "Uygulama açılırken \(biometricManager.biometricType.name) iste")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Açma/kapama toggle'ı
                Toggle("", isOn: $biometricManager.isBiometricEnabled)
                    .labelsHidden()
                    .tint(AppColors.primary)
                    .disabled(biometricManager.biometricType == .none) // Biyometrik yoksa devre dışı
                    .onChange(of: biometricManager.isBiometricEnabled) { oldValue, newValue in
                        // Toggle değiştiğinde sadece ayarı kaydet
                        // Otomatik test yapmıyorum artık (bug fix)
                        biometricManager.saveSettings()
                        
                        if newValue {
                            print("✅ Face ID kilidi aktif edildi")
                        } else {
                            print("❌ Face ID kilidi kapatıldı")
                        }
                    }
            }
            
            // Cihazda biyometrik yoksa uyarı göster
            if biometricManager.biometricType == .none {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.moodYellow)
                    
                    Text("Cihazınızda Face ID veya Touch ID ayarlanmamış")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.surfaceLight.opacity(0.5))
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
    
    // MARK: - Info Section
    // Kullanıcıya bilgilendirme mesajları
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppColors.moodYellow)
                Text("Bilgi")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                infoRow(
                    icon: "checkmark.shield.fill",
                    text: "Günlükleriniz cihazınızda güvende saklanır",
                    color: AppColors.moodGreen
                )
                
                infoRow(
                    icon: "faceid",
                    text: "Sadece siz günlüklerinize erişebilirsiniz",
                    color: AppColors.primary
                )
                
                infoRow(
                    icon: "lock.fill",
                    text: "Uygulama her açılışta kilit açma ister",
                    color: AppColors.moodBlue
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
    
    // Bilgilendirme satırı komponenti
    private func infoRow(icon: String, text: String, color: Color) -> some View {
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
    
    
    }

//
//  BiometricLockView.swift
//  AIMoodJournal
//
//  Face ID / Touch ID kilit ekranı
//  Uygulama açılırken kullanıcının kimliğini doğrulamak için gösteriliyor
//

import SwiftUI

struct BiometricLockView: View {
    // Biyometrik (Face ID/Touch ID) yöneticisi
    @StateObject private var biometricManager = BiometricManager.shared
    
    // Hata mesajı gösterme durumu
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Logo animasyonu için
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Arka plan - koyu kahverengi
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Animasyonlu kilit ikonu
                lockIcon
                
                // "Günlükleriniz Güvende" başlığı
                titleSection
                
                // "Kilidi Aç" butonu
                unlockButton
                
                // Hata mesajı (doğrulama başarısız olursa)
                if showError {
                    errorSection
                }
                
                Spacer()
                Spacer()
                
                // Alt bilgi - "Gizliliğiniz bizim için önemli"
                footerText
            }
            .padding(AppSpacing.lg)
        }
        .onAppear {
            // Ekran açılır açılmaz otomatik doğrulama başlat
            // 0.5 saniye bekleyip Face ID'yi tetikle
            if biometricManager.isBiometricEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateUser()
                }
            }
        }
    }
    
    // MARK: - Lock Icon
    // Ortadaki animasyonlu kilit ikonu tasarımı
    private var lockIcon: some View {
        ZStack {
            // Arka planda ışıltılı glow efekti
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primary.opacity(0.3),
                            AppColors.primary.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.2 : 1.0) // Büyüyüp küçülen animasyon
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // İkon arka plan çemberi
            Circle()
                .fill(AppColors.surface)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
            
            // Face ID veya Touch ID ikonu (cihaza göre)
            Image(systemName: biometricManager.biometricType.icon)
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.05 : 1.0) // Hafif pulse efekti
        }
        .onAppear {
            isAnimating = true // Animasyonu başlat
        }
    }
    
    // MARK: - Title Section
    // Başlık ve açıklama metinleri
    private var titleSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Günlükleriniz Güvende")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Devam etmek için \(biometricManager.biometricType.name) kullanın")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Unlock Button
    // "Kilidi Aç" butonu - manuel doğrulama için
    private var unlockButton: some View {
        Button(action: {
            authenticateUser()
        }) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: biometricManager.biometricType.icon)
                    .font(.system(size: 20))
                
                Text("Kilidi Aç")
                    .font(AppFonts.headline)
            }
            .foregroundColor(AppColors.background)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 10, y: 5)
            )
        }
        .padding(.horizontal, AppSpacing.xl)
    }
    
    // MARK: - Error Section
    // Doğrulama başarısız olduğunda gösterilen hata mesajı
    private var errorSection: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.moodPink)
            
            Text(errorMessage)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(AppColors.moodPink.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppSpacing.lg)
        .transition(.scale.combined(with: .opacity)) // Animasyonlu giriş/çıkış
    }
    
    // MARK: - Footer
    // Alt kısımdaki bilgilendirme
    private var footerText: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Gizliliğiniz bizim için önemli")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }
    
    // MARK: - Authentication Function
    // Kullanıcının kimliğini doğrulayan fonksiyon
    private func authenticateUser() {
        // Önceki hata mesajını temizle
        showError = false
        
        // BiometricManager'dan doğrulama iste
        biometricManager.authenticate { success, error in
            if !success {
                // Doğrulama başarısız - hata mesajını göster
                withAnimation {
                    errorMessage = error ?? "Doğrulama başarısız"
                    showError = true
                }
                
                // 3 saniye sonra hata mesajını otomatik kaldır
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showError = false
                    }
                }
            }
            // Başarılı ise BiometricManager otomatik olarak
            // isAuthenticated = true yapıyor ve kilit ekranı kapanıyor
        }
    }
}

struct BiometricLockView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricLockView()
    }
}

//
//  OnboardingView.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 14.11.2025.
//
//  İlk açılışta gösterilen hoş geldin ekranları
//  Kullanıcıya uygulamanın özelliklerini tanıtıyor
//

import SwiftUI

// MARK: - Onboarding Model
// Her bir onboarding sayfasının modelini tanımlıyorum
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String           // SF Symbol ikonu
    let title: String          // Başlık
    let description: String    // Açıklama
    let color: Color          // Sayfanın teması rengi
}

// MARK: - Onboarding View
struct OnboardingView: View {
    // Kullanıcı onboarding'i gördü mü? (UserDefaults'ta saklanıyor)
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // Şu an hangi sayfadayız?
    @State private var currentPage = 0
    
    // 4 sayfalık onboarding içeriği
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.pages.fill",
            title: "AI Ruh Hali Günlüğün",
            description: "Her gün duygularını yaz, AI sana özel analizler yapsın",
            color: AppColors.primary
        ),
        OnboardingPage(
            icon: "mic.fill",
            title: "Sesli Not Al",
            description: "Yazmak istemediğinde konuş, metne dönüştürelim",
            color: AppColors.accent
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Analizler & İçgörüler",
            description: "Ruh hali desenlerini gör, kendini daha iyi tanı",
            color: AppColors.secondary
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Güvenli & Özel",
            description: "Verileriniz Face ID ile korunuyor, sadece size özel",
            color: AppColors.moodGreen
        )
    ]
    
    var body: some View {
        ZStack {
            // Arka plan - mevcut sayfanın rengine göre değişen gradient
            LinearGradient(
                colors: [
                    AppColors.background,
                    pages[currentPage].color.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Sayfa göstergesi (üstteki noktalar)
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? pages[currentPage].color : .white.opacity(0.3))
                            .frame(width: index == currentPage ? 32 : 8, height: 8) // Aktif sayfa daha uzun
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 40)
                
                // Sayfalar arası swipe ile geçiş
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Varsayılan nokta göstergesini gizle
                .animation(.easeInOut, value: currentPage)
                
                // Alt butonlar
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Son sayfadaysa "Başlayalım" butonu
                        Button(action: {
                            withAnimation(.spring(response: 0.5)) {
                                hasSeenOnboarding = true // Onboarding'i tamamlandı olarak işaretle
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("Hadi Başlayalım")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                    } else {
                        // Diğer sayfalarda "İleri" butonu
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                currentPage += 1 // Sonraki sayfaya geç
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("İleri")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(pages[currentPage].color) // Mevcut sayfanın rengi
                            .cornerRadius(16)
                        }
                    }
                    
                    // Son sayfa değilse "Atla" butonu göster
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.5)) {
                                hasSeenOnboarding = true // Direkt uygulamaya geç
                            }
                        }) {
                            Text("Atla")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Page View
// Her bir onboarding sayfasının içeriği
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            // İkon - çift halkalı tasarım
            ZStack {
                // Dış halka
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                
                // İç halka
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                // Merkezdeki ikon
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.color)
            }
            .shadow(color: page.color.opacity(0.3), radius: 30, x: 0, y: 15)
            
            VStack(spacing: 16) {
                // Başlık
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Açıklama
                Text(page.description)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6) // Satır arası boşluk
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingView()
}

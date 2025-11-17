//
//  MainTabView.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 05.11.2025.
//
//  Ana tab bar navigation'ı yöneten view
//  Home, Takvim ve İstatistik sayfaları arasında geçiş sağlıyor
//

import SwiftUI

struct MainTabView: View {
    // Hangi tab seçili - 0: Ana Sayfa, 1: Takvim, 2: İstatistik
    @State private var selectedTab = 0
    
    // Hatırlatıcı ayarları modalını göster/gizle
    @State private var showingReminderSettings = false
    
    // Güvenlik (Face ID) ayarları modalını göster/gizle
    @State private var showingSecuritySettings = false
    
    var body: some View {
        ZStack {
            // Arka plan rengi - koyu kahverengi ton
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Üst başlık ve ayarlar butonları
                HStack {
                    Text("Ruh Hali Günlüğüm")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: AppSpacing.sm) {
                        // Güvenlik Ayarları Butonu (Face ID kilidi için)
                        Button(action: {
                            showingSecuritySettings = true
                        }) {
                            ZStack {
                                // Buton arka planı
                                Circle()
                                    .fill(AppColors.surface)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                                
                                // Kilit ikonu - gradient renkli
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.moodGreen, AppColors.moodBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.system(size: 18))
                                    .shadow(color: AppColors.moodGreen.opacity(0.3), radius: 4)
                            }
                        }
                        
                        // Hatırlatıcı Ayarları Butonu
                        Button(action: {
                            showingReminderSettings = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.surface)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                                
                                // Bildirim ikonu - gradient renkli
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.accent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.system(size: 18))
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)
                
                // Sayfa içeriği - swipe ile geçiş yapılabiliyor
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(0)
                    
                    CalendarView()
                        .tag(1)
                    
                    StatisticsView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Nokta göstergelerini gizle
                
                // Özel tasarladığım alt tab bar
                customTabBar
            }
        }
        // Hatırlatıcı ayarları modalı
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView()
        }
        // Güvenlik ayarları modalı
        .sheet(isPresented: $showingSecuritySettings) {
            SecuritySettingsView()
        }
        .onAppear {
            // Uygulama açılınca bildirim badge'ini temizle
            NotificationManager.shared.clearBadge()
        }
    }
    
    // MARK: - Custom Tab Bar
    // Alt kısımda gösterdiğim özel tab bar tasarımı
    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Ana Sayfa butonu
            TabBarButton(
                icon: "house.fill",
                title: "Ana Sayfa",
                isSelected: selectedTab == 0,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
            )
            
            // Takvim butonu
            TabBarButton(
                icon: "calendar",
                title: "Takvim",
                isSelected: selectedTab == 1,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
            )
            
            // İstatistik butonu
            TabBarButton(
                icon: "chart.bar.fill",
                title: "İstatistik",
                isSelected: selectedTab == 2,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            )
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.md)
        .background(
            // Tab bar arka planı - yuvarlatılmış köşeli, gölgeli
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
    }
}

// MARK: - Tab Bar Button Component
// Her bir tab için kullandığım özel buton komponenti
struct TabBarButton: View {
    let icon: String          // SF Symbol ikonu
    let title: String         // Buton başlığı
    let isSelected: Bool      // Seçili mi?
    let action: () -> Void    // Tıklanınca ne olacak
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Seçili tab için arka planda ışıltı efekti
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary.opacity(0.15))
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                    }
                    
                    // Tab ikonu
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            isSelected ?
                            // Seçiliyse gradient renk
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            // Değilse gri
                            LinearGradient(
                                colors: [AppColors.textTertiary, AppColors.textTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0) // Seçiliyse biraz büyüt
                        .shadow(
                            color: isSelected ? AppColors.primary.opacity(0.3) : .clear,
                            radius: 4
                        )
                }
                
                // Tab başlığı
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                // Seçili tab için hafif arka plan
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? AppColors.surfaceLight.opacity(0.5) : Color.clear)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

//
//  SplashScreen.swift
//  AIMoodJournal
//
//  Face ID başarılı olduktan sonra gösterilen yükleme ekranı
//  Kullanıcıya hoş bir açılış animasyonu sunuyor
//

import SwiftUI

struct SplashScreen: View {
    // Animasyon için state'ler
    @State private var scale: CGFloat = 0.8      // Logo büyüklüğü
    @State private var opacity: Double = 0       // Görünürlük
    @State private var rotation: Double = 0      // Dış halkadaki dönme açısı
    
    var body: some View {
        ZStack {
            // Arka plan - gradient kahverengi tonları
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.primary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Animasyonlu logo tasarımı
                ZStack {
                    // Dış halka - sürekli dönen gradient halka
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotation)) // Döndürme animasyonu
                    
                    // İç halka - nabız gibi büyüyüp küçülen halka
                    Circle()
                        .fill(AppColors.primary.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(scale) // Pulse efekti
                    
                    // Merkezdeki günlük ikonu
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.primary)
                }
                .scaleEffect(scale)    // Tüm logo büyüyerek beliriyor
                .opacity(opacity)      // Fade in efekti
                
                // "Açılıyor" yazısı ve animasyonlu noktalar
                VStack(spacing: 12) {
                    Text("Açılıyor")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    // Yükleniyor animasyonu için 3 nokta
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(scale)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2), // Her nokta sırayla hareket ediyor
                                    value: scale
                                )
                        }
                    }
                    .opacity(opacity)
                }
            }
        }
        .onAppear {
            // Ekran açıldığında animasyonları başlat
            
            // Fade in ve büyüme animasyonu
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Dış halkanın sürekli dönmesi
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Pulse efekti - sürekli büyüyüp küçülme
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
        }
    }
}

#Preview {
    SplashScreen()
}

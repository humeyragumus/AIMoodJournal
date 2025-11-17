//
//  AIMoodJournalApp.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 01.11.2025.
//
//  Uygulamanın ana giriş noktası
//  Face ID kilidi, onboarding ve splash screen yönetimi
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct AIMoodJournalApp: App {
    // Core Data için persistence controller - veritabanı yönetimi
    let persistenceController = PersistenceController.shared
    
    // Uygulama yaşam döngüsü için delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Biyometrik (Face ID/Touch ID) yöneticisi
    @StateObject private var biometricManager = BiometricManager.shared
    
    // Kullanıcı onboarding'i gördü mü? (İlk açılış kontrolü için)
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // Face ID başarılı olduktan sonra splash screen göstermek için
    @State private var showSplash = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // İlk açılışta onboarding ekranlarını göster
                if !hasSeenOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    // Face ID doğrulandıktan sonra splash screen
                    if showSplash {
                        SplashScreen()
                            .transition(.opacity)
                            .zIndex(1000) // En üstte göster
                    }
                    
                    // Ana uygulama ekranı
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .preferredColorScheme(.dark) // Dark mode zorunlu
                        .blur(radius: showSplash ? 10 : 0) // Splash açıkken arka planı bulanıklaştır
                    
                    // Face ID kilidi (aktifse ve doğrulanmadıysa göster)
                    if biometricManager.isBiometricEnabled && !biometricManager.isAuthenticated {
                        BiometricLockView()
                            .transition(.opacity)
                            .zIndex(999) // Splash'in altında ama ana ekranın üstünde
                    }
                }
            }
            .onAppear {
                // Uygulama açılınca cihazın biyometrik tipini kontrol et
                biometricManager.checkBiometricType()
            }
            // Face ID durumunu dinle - başarılı olunca splash göster
            .onChange(of: biometricManager.isAuthenticated) { oldValue, newValue in
                if newValue && !oldValue {
                    // Face ID başarılı! Splash animasyonunu başlat
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSplash = true
                    }
                    
                    // 2.5 saniye sonra splash'i kapat ve ana ekrana geç
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - App Delegate
// Uygulama yaşam döngüsü ve bildirim yönetimi için
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // Uygulama başlatıldığında çağrılır
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Bildirim delegate'ini ayarla
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Uygulama arka plana geçtiğinde otomatik kilitle
    func applicationDidEnterBackground(_ application: UIApplication) {
        if BiometricManager.shared.isBiometricEnabled {
            BiometricManager.shared.lock()
            print("🔒 Uygulama arka plana geçti, güvenlik için kilitlendi")
        }
    }
    
    // Uygulama açıkken bildirim gelirse nasıl gösterileceğini belirle
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Banner, ses ve badge ile göster
        completionHandler([.banner, .sound, .badge])
    }
    
    // Kullanıcı bildirime tıkladığında çağrılır
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Badge sayısını sıfırla
        UNUserNotificationCenter.current().setBadgeCount(0)
        completionHandler()
    }
}

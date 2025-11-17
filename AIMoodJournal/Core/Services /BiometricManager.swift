//
//  BiometricManager.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 13.11.2025.
//
//  🔒 Biyometrik doğrulama (Face ID / Touch ID) yönetimi
//  Uygulamayı açarken kullanıcının kimliğini doğruluyor
//

import SwiftUI
import LocalAuthentication
import Combine

// MARK: - Biometric Manager
/// Uygulama genelinde biyometrik doğrulama işlemlerini yöneten singleton class
/// Face ID, Touch ID veya şifre ile kimlik doğrulama sağlıyor
class BiometricManager: ObservableObject {
    
    // Singleton instance - uygulama boyunca tek bir BiometricManager var
    static let shared = BiometricManager()
    
    // MARK: - Published Properties
    // @Published = Bu değer değişince bağlı olan tüm View'lar otomatik güncellenir
    
    /// Kullanıcının kimliği doğrulandı mı?
    @Published var isAuthenticated = false
    
    /// Biyometrik kilit açık/kapalı durumu (kullanıcı ayarlardan açıp kapatabilir)
    @Published var isBiometricEnabled = false
    
    /// Cihazda hangi biyometrik yöntem var?
    @Published var biometricType: BiometricType = .none
    
    // MARK: - Biometric Type Enum
    /// Cihazda mevcut biyometrik doğrulama türü
    enum BiometricType {
        case faceID      // iPhone X ve sonrası
        case touchID     // Home button'lu cihazlar
        case none        // Biyometrik yok
        
        // SF Symbols icon adı
        var icon: String {
            switch self {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            case .none:
                return "lock.fill"
            }
        }
        
        // Kullanıcıya gösterilecek isim
        var name: String {
            switch self {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .none:
                return "Şifre"
            }
        }
    }
    
    // MARK: - Initialization
    /// Private init - sadece singleton instance oluşturulabilir
    /// İlk açılışta kayıtlı ayarları yüklüyor
    private init() {
        loadSettings() // Kullanıcı biyometrik kilidi açmış mı?
        checkBiometricType() // Cihazda hangi biyometrik var?
    }
    
    // MARK: - Biometric Type Check
    
    /// Cihazda hangi biyometrik yöntemin olduğunu kontrol ediyor
    func checkBiometricType() {
        let context = LAContext() // LocalAuthentication context'i
        var error: NSError?
        
        // Biyometrik doğrulama mevcut mu?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        
        // Hangi tip biyometrik var?
        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
            print("🔒 Cihazda Face ID mevcut")
        case .touchID:
            biometricType = .touchID
            print("🔒 Cihazda Touch ID mevcut")
        case .none:
            biometricType = .none
            print("🔒 Biyometrik doğrulama yok")
        case .opticID:
            // Apple Vision Pro için Optic ID
            biometricType = .none
            print("🔒 Optic ID desteklenmiyor (şimdilik)")
        @unknown default:
            biometricType = .none
            print("🔒 Bilinmeyen biyometrik tip")
        }
    }
    
    // MARK: - Authentication
    
    /// Biyometrik doğrulama yapıyor (Face ID / Touch ID)
    /// Kullanıcı uygulamayı açarken bu fonksiyon çağrılıyor
    /// - Parameter completion: Doğrulama sonucu (başarılı/başarısız) ve hata mesajı
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Biyometrik doğrulama mevcut mu kontrol et
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biyometrik yoksa şifre ile dene
            authenticateWithPasscode(completion: completion)
            return
        }
        
        // Kullanıcıya gösterilecek mesaj (Face ID popup'ında görünür)
        let reason = "Günlüklerinize erişmek için kimliğinizi doğrulayın"
        
        // Biyometrik doğrulama başlat (Face ID veya Touch ID açılır)
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            // UI güncelleme için main thread'e geç
            DispatchQueue.main.async {
                if success {
                    //  Doğrulama başarılı
                    self.isAuthenticated = true
                    print("✅ Biyometrik doğrulama başarılı")
                    completion(true, nil)
                } else {
                    //  Doğrulama başarısız
                    let errorMessage = self.getErrorMessage(from: authError)
                    print("❌ Biyometrik doğrulama başarısız: \(errorMessage)")
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    /// Şifre ile doğrulama (biyometrik yoksa veya başarısız olursa)
    /// Fallback olarak kullanılıyor
    private func authenticateWithPasscode(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        let reason = "Günlüklerinize erişmek için şifrenizi girin"
        
        // Cihaz şifresi ile doğrulama (şifre ekranı açılır)
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    print("✅ Şifre doğrulama başarılı")
                    completion(true, nil)
                } else {
                    let errorMessage = self.getErrorMessage(from: error)
                    print("❌ Şifre doğrulama başarısız: \(errorMessage)")
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Biyometrik hata mesajlarını Türkçe'ye çeviriyor
    /// LocalAuthentication API'sinin İngilizce hatalarını kullanıcı dostu Türkçe mesajlara dönüştürüyor
    private func getErrorMessage(from error: Error?) -> String {
        guard let error = error as? LAError else {
            return "Bilinmeyen bir hata oluştu"
        }
        
        // Her hata kodunu Türkçe'ye çevir
        switch error.code {
        case .authenticationFailed:
            return "Kimlik doğrulama başarısız"
        case .userCancel:
            return "İşlem iptal edildi"
        case .userFallback:
            return "Şifre ile giriş yapın"
        case .biometryNotAvailable:
            return "Biyometrik doğrulama mevcut değil"
        case .biometryNotEnrolled:
            return "Biyometrik doğrulama ayarlanmamış"
        case .biometryLockout:
            return "Çok fazla başarısız deneme. Şifrenizi kullanın"
        case .appCancel:
            return "Uygulama tarafından iptal edildi"
        case .invalidContext:
            return "Geçersiz bağlam"
        case .notInteractive:
            return "İnteraktif mod değil"
        case .passcodeNotSet:
            return "Cihaz şifresi ayarlanmamış"
        case .systemCancel:
            return "Sistem tarafından iptal edildi"
        case .touchIDNotAvailable:
            return "Touch ID mevcut değil"
        case .touchIDNotEnrolled:
            return "Touch ID ayarlanmamış"
        case .touchIDLockout:
            return "Touch ID kilitlendi"
        case .companionNotAvailable:
            return "Apple Watch mevcut değil"
        @unknown default:
            return "Bir hata oluştu"
        }
    }
    
    // MARK: - Lock/Unlock
    
    /// Uygulamayı kilitle (kullanıcı uygulamadan çıkarken veya arka plana atarken)
    func lock() {
        isAuthenticated = false
        print("🔒 Uygulama kilitlendi")
    }
    
    /// Test amaçlı manuel unlock (sadece development'ta kullanılıyor)
    func unlock() {
        isAuthenticated = true
        print("🔓 Uygulama kilidi açıldı (manuel)")
    }
    
    // MARK: - Settings Persistence
    
    /// Biyometrik kilit ayarını UserDefaults'a kaydet
    /// Kullanıcı Settings'te "Biyometrik Kilit" açıp kapattığında bu fonksiyon çağrılıyor
    func saveSettings() {
        UserDefaults.standard.set(isBiometricEnabled, forKey: "biometricLockEnabled")
        print("💾 Biyometrik kilit ayarı kaydedildi: \(isBiometricEnabled)")
    }
    
    /// Kayıtlı biyometrik kilit ayarını UserDefaults'tan yükle
    /// Uygulama açılırken çağrılıyor
    private func loadSettings() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricLockEnabled")
        print("📥 Biyometrik kilit ayarı yüklendi: \(isBiometricEnabled)")
    }
}

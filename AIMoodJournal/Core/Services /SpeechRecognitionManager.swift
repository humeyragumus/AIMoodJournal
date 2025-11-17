//
//  SpeechRecognitionManager.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 08.11.2025.
//
//  Konuşma Tanıma (Speech to Text) Yöneticisi
//  Kullanıcının konuştuğunu metne çeviriyor - Türkçe destekli
//  HomeView'daki mikrofon butonu bu manager'ı kullanıyor
//

import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Speech Recognition Manager
/// Konuşma tanıma işlemlerini yöneten singleton class
/// iOS Speech framework kullanarak real-time transcription yapıyor
/// Kullanıcı konuştukça metni anında güncelliyor
class SpeechRecognitionManager: ObservableObject {
    
    // Singleton instance - uygulama boyunca tek bir SpeechRecognitionManager var
    static let shared = SpeechRecognitionManager()
    
    // MARK: - Published Properties
    // @Published = Bu değerler değişince bağlı olan View'lar otomatik güncellenir
    
    /// Mikrofon açık mı? (kayıt devam ediyor mu?)
    @Published var isRecording = false
    
    /// Tanınan metin (real-time güncelleniyor - kullanıcı konuştukça)
    @Published var recognizedText = ""
    
    /// Hata mesajı varsa (izin reddedildi, mikrofon bulunamadı, vs.)
    @Published var errorMessage: String?
    
    /// İzin durumu (authorized, denied, notDetermined, vs.)
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    /// Speech recognizer - Türkçe için ayarlanmış
    private var speechRecognizer: SFSpeechRecognizer?
    
    /// Audio engine - mikrofon sesini yakalar
    private var audioEngine: AVAudioEngine?
    
    /// Recognition request - ses buffer'larını Apple'a gönderir
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Recognition task - aktif tanıma işlemi
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Initialization
    /// Private init - sadece singleton instance oluşturulabilir
    private init() {
        // Türkçe için speech recognizer oluştur
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
        audioEngine = AVAudioEngine()
        
        // İzin durumunu kontrol et
        checkAuthorization()
        
        print("🎤 SpeechRecognitionManager başlatıldı")
    }
    
    // MARK: - Authorization
    
    /// Mevcut izin durumunu kontrol et
    /// Uygulama açılırken çağrılıyor
    func checkAuthorization() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        print("🎤 İzin durumu: \(authorizationStatus.rawValue)")
    }
    
    /// Mikrofon ve konuşma tanıma izni iste
    /// Kullanıcıya izin popup'ı gösterir
    func requestAuthorization() {
        // Önce konuşma tanıma izni
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                
                switch status {
                case .authorized:
                    print("✅ Konuşma tanıma izni verildi")
                    // Konuşma tanıma izni verildiyse mikrofon izni de iste
                    self.requestMicrophonePermission()
                case .denied:
                    self.errorMessage = "Konuşma tanıma izni reddedildi"
                    print("❌ Konuşma tanıma izni reddedildi")
                case .restricted:
                    self.errorMessage = "Konuşma tanıma kısıtlı"
                    print("⚠️ Konuşma tanıma kısıtlı")
                case .notDetermined:
                    print("❓ İzin durumu belirlenmedi")
                @unknown default:
                    self.errorMessage = "Bilinmeyen izin durumu"
                }
            }
        }
    }
    
    /// Mikrofon izni iste
    /// iOS 17+ ve öncesi için farklı API'ler kullanılıyor
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            // iOS 17+ için yeni API
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Mikrofon izni verildi")
                    } else {
                        self.errorMessage = "Mikrofon izni reddedildi"
                        print("❌ Mikrofon izni reddedildi")
                    }
                }
            }
        } else {
            // iOS 17 öncesi için eski API
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Mikrofon izni verildi")
                    } else {
                        self.errorMessage = "Mikrofon izni reddedildi"
                        print("❌ Mikrofon izni reddedildi")
                    }
                }
            }
        }
    }
    
    // MARK: - Recording Control
    
    /// Kaydı başlat (konuşmayı dinlemeye başla)
    /// Kullanıcı mikrofon butonuna bastığında çağrılıyor
    func startRecording() {
        // İzin kontrolü
        guard authorizationStatus == .authorized else {
            errorMessage = "Konuşma tanıma izni gerekli"
            requestAuthorization()
            return
        }
        
        // Speech recognizer kullanılabilir mi?
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Konuşma tanıma kullanılamıyor"
            return
        }
        
        // Eğer zaten kayıt varsa durdur
        if isRecording {
            stopRecording()
            return
        }
        
        do {
            // Audio session ayarla (mikrofon için)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Recognition request oluştur
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Recognition request oluşturulamadı"
                return
            }
            
            // Partial results istiyoruz (kullanıcı konuştukça güncelleme)
            recognitionRequest.shouldReportPartialResults = true
            
            // Audio engine'i ayarla
            guard let audioEngine = audioEngine else {
                errorMessage = "Audio engine bulunamadı"
                return
            }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Mikrofon sesini dinle ve buffer'lara kaydet
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            // Audio engine'i başlat
            audioEngine.prepare()
            try audioEngine.start()
            
            // Recognition task başlat (Apple'a ses gönderip metin al)
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                var isFinal = false
                
                if let result = result {
                    // Tanınan metni güncelle (real-time)
                    DispatchQueue.main.async {
                        self.recognizedText = result.bestTranscription.formattedString
                        print("🎤 Tanınan: \(self.recognizedText)")
                    }
                    isFinal = result.isFinal
                }
                
                // Hata kontrolü (error code 216 = cancel, bunu gösterme)
                if let error = error as NSError? {
                    // Error code 216 = "Recognition request was canceled" - bu normal
                    if error.code != 216 {
                        DispatchQueue.main.async {
                            self.errorMessage = "Tanıma hatası: \(error.localizedDescription)"
                            print("❌ Tanıma hatası: \(error)")
                        }
                    }
                }
                
                if isFinal {
                    // Sonuç finallenmişse durdur
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            }
            
            // Kayıt durumunu güncelle
            isRecording = true
            errorMessage = nil
            print("🎤 Kayıt başladı")
            
        } catch {
            errorMessage = "Audio session başlatılamadı: \(error.localizedDescription)"
            print("❌ Audio session hatası: \(error)")
        }
    }
    
    /// Kaydı durdur
    /// Kullanıcı tekrar mikrofon butonuna bastığında veya analiz butonuna bastığında çağrılıyor
    func stopRecording() {
        guard let audioEngine = audioEngine, audioEngine.isRunning else {
            return
        }
        
        // Audio engine'i durdur
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Recognition'ı bitir (cancel yerine finish - son kelimeleri de yakalar)
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        
        // Biraz bekle ki son kelimeler de yakalansın
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.recognitionRequest = nil
            self.recognitionTask = nil
        }
        
        // Audio session'ı deaktive et
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Audio session deaktive edilemedi: \(error)")
        }
        
        isRecording = false
        errorMessage = nil // Hata mesajını temizle
        print("🎤 Kayıt durduruldu")
    }
    
    /// Tanınan metni temizle
    /// Yeni kayıt başlatırken veya kullanıcı silmek istediğinde çağrılıyor
    func clearText() {
        recognizedText = ""
        errorMessage = nil
        print("🗑️ Metin temizlendi")
    }
    
    /// Toggle recording (başlat/durdur)
    /// Mikrofon butonuna basıldığında çağrılıyor
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Utility
    
    /// Speech recognizer kullanılabilir mi?
    /// Bazı cihazlarda veya durumlarında speech recognition kapalı olabilir
    var isAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    /// Türkçe destekleniyor mu?
    /// Cihazda Türkçe konuşma tanıma paketi yüklü mü kontrol ediyor
    var isTurkishSupported: Bool {
        return SFSpeechRecognizer(locale: Locale(identifier: "tr-TR")) != nil
    }
}

// MARK: - Authorization Status Extension
/// SFSpeechRecognizerAuthorizationStatus için Türkçe açıklama
extension SFSpeechRecognizerAuthorizationStatus {
    /// İzin durumunu Türkçe olarak döndür
    var description: String {
        switch self {
        case .notDetermined:
            return "Henüz belirlenmedi"
        case .denied:
            return "Reddedildi"
        case .restricted:
            return "Kısıtlı"
        case .authorized:
            return "İzin verildi"
        @unknown default:
            return "Bilinmiyor"
        }
    }
}

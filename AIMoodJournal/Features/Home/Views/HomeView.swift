//
//  HomeView.swift
//  AIMoodJournal
//
//  Created by Humeyra Gümüş on 02.11.2025.
//
//  Ana ekran - günlük yazma ve AI analizi
//  Günde sadece 1 entry sistemi: Aynı gün tekrar yazarsan güncelleniyor
//

import SwiftUI
import Speech

struct HomeView: View {
    // Günlük metni
    @State private var journalText: String = ""
    
    // AI analizi durumu
    @State private var isAnalyzing: Bool = false
    @State private var currentMoodData: MoodData?
    @State private var showMoodSheet: Bool = false
    
    // Bugünkü entry kontrolü - Günde 1 entry sistemi
    @State private var todayEntry: MoodEntry?
    @State private var isEditingToday: Bool = false
    
    // Sesli not için speech recognition
    @StateObject private var speechRecognizer = SpeechRecognitionManager.shared
    @State private var showMicrophonePermission = false
    
    // Placeholder metni - düzenleme moduna göre değişiyor
    private var placeholderText: String {
        if isEditingToday {
            return "Bugünkü günlüğünü düzenle..."
        } else {
            return "Bugün nasıl hissediyorsun?\n\nDüşüncelerini, duygularını özgürce yaz..."
        }
    }
    
    // Arka plan animasyonu için
    @State private var animateGradient: Bool = false
    
    var body: some View {
        ZStack {
            // Animasyonlu gradient arka plan
            AnimatedGradientBackground()
                .onTapGesture {
                    hideKeyboard() // Arka plana tıklanınca klavyeyi kapat
                }
            
            // Ana içerik
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    
                    // Başlık ve tarih
                    headerSection
                        .onTapGesture {
                            hideKeyboard()
                        }
                    
                    // Bugünkü entry'yi düzenliyorsan bilgilendirme banner'ı göster
                    if isEditingToday {
                        editingTodayBanner
                            .onTapGesture {
                                hideKeyboard()
                            }
                    }
                    
                    // Günlük yazma kartı
                    journalCard
                }
                .padding(.horizontal, 24)
            }
        }
        .ignoresSafeArea()
        // AI analiz sonuçları modalı
        .sheet(isPresented: $showMoodSheet, onDismiss: {
            // Modal kapandığında bugünkü entry'yi kontrol et
            // Kullanıcının yazdığı metni değiştirme!
            let entries = StorageService.shared.fetchAllEntries()
            let calendar = Calendar.current
            todayEntry = entries.first { entry in
                calendar.isDateInToday(entry.date)
            }
            
            if todayEntry != nil {
                isEditingToday = true
                print("📅 Bugünkü entry bulundu")
            } else {
                isEditingToday = false
                print("📅 Bugünkü entry yok")
            }
        }) {
            if let moodData = currentMoodData {
                MoodResultSheet(moodData: moodData, journalText: journalText)
            }
        }
        // Mikrofon izin uyarısı
        .alert("Mikrofon İzni", isPresented: $showMicrophonePermission) {
            Button("Ayarlara Git") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Sesli not kullanabilmek için mikrofon ve konuşma tanıma iznine ihtiyacımız var. Lütfen ayarlardan izin verin.")
        }
        // Speech recognizer'dan gelen metni otomatik ekle
        .onChange(of: speechRecognizer.recognizedText) { oldValue, newValue in
            if !newValue.isEmpty && speechRecognizer.isRecording {
                journalText = newValue
            }
        }
        .onAppear {
            // Mikrofon izin durumunu kontrol et
            speechRecognizer.checkAuthorization()
            
            // Önce duplicate (tekrarlayan) entry'leri temizle
            StorageService.shared.cleanDuplicateEntries()
            
            // Bugünkü entry var mı kontrol et
            checkTodayEntry()
        }
    }
    
    // MARK: - Editing Today Banner
    // Bugünkü entry'yi düzenliyorsan gösterilen bilgilendirme
    private var editingTodayBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.circle.fill")
                .foregroundColor(AppColors.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bugünkü Günlüğünü Düzenliyorsun")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Önceki ruh halini göster
                if let entry = todayEntry, let mood = entry.moodData?.mood {
                    Text("Önceki ruh halin: \(mood.emoji) \(mood.name)")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Yeni günlük başlat butonu
            Button(action: {
                journalText = ""
                todayEntry = nil
                isEditingToday = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.primary.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Header
    // Başlık ve tarih
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Animasyonlu nokta
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 12, height: 12)
                    .shadow(color: AppColors.primary.opacity(0.5), radius: 8, x: 0, y: 0)
                
                Text("Ruh Hali Günlüğüm")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Bugünün tarihi
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Journal Card
    // Günlük yazma kartı - text editor ve analiz butonu
    private var journalCard: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                
                Text(isEditingToday ? "Güncelle" : "Bugünü Anlat")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Mikrofon butonu (sesli not için)
                microphoneButton
            }
            
            // Metin editörü
            ZStack(alignment: .topLeading) {
                // Placeholder metni (metin boşken göster)
                if journalText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(speechRecognizer.isRecording ? "Dinliyorum... 🎤" : (isEditingToday ? "Bugünkü günlüğünü düzenle..." : "Bugün nasıl hissediyorsun?"))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                        
                        if !speechRecognizer.isRecording {
                            Text("Düşüncelerini yaz veya mikrofona dokun...")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(20)
                }
                
                // Gerçek text editor
                TextEditor(text: $journalText)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden) // Varsayılan arka planı gizle
                    .padding(16)
                    .frame(minHeight: 180)
                    .disabled(speechRecognizer.isRecording) // Kayıt sırasında yazma engelle
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: speechRecognizer.isRecording
                                    ? [AppColors.primary.opacity(0.5), AppColors.accent.opacity(0.5)] // Kayıt sırasında renkli
                                    : [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: speechRecognizer.isRecording ? 2 : 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            
            // Hata mesajı (mikrofon vs. hatalarında göster)
            if let errorMessage = speechRecognizer.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.moodPink)
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.moodPink.opacity(0.1))
                )
            }
            
            // "Analiz Et" butonu
            Button(action: {
                // Haptic feedback (titreşim)
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                // Kayıt devam ediyorsa önce durdur
                if speechRecognizer.isRecording {
                    speechRecognizer.stopRecording()
                }
                
                // AI analizini başlat
                Task {
                    await analyzeMood()
                }
            }) {
                HStack(spacing: 12) {
                    if isAnalyzing {
                        // Analiz devam ederken loading göster
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(isEditingToday ? "Yeniden Analiz Et" : "Ruh Halimi Analiz Et")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    ZStack {
                        // Gradient arka plan
                        LinearGradient(
                            colors: journalText.isEmpty || isAnalyzing
                            ? [AppColors.primary.opacity(0.3), AppColors.secondary.opacity(0.3)] // Devre dışıyken soluk
                            : [AppColors.primary, AppColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // Aktifken ışıltılı efekt
                        if !journalText.isEmpty && !isAnalyzing {
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: journalText.isEmpty || isAnalyzing
                    ? .clear
                    : AppColors.primary.opacity(0.5),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
            .disabled(journalText.isEmpty || isAnalyzing) // Metin yoksa veya analiz devam ediyorsa buton devre dışı
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnalyzing)
        }
        .padding(24)
        .background(GlassmorphicCard()) // Cam efektli kart arka planı
    }
    
    // MARK: - Microphone Button
    // Sesli not almak için mikrofon butonu
    private var microphoneButton: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // İzin kontrolü
            if speechRecognizer.authorizationStatus != .authorized {
                speechRecognizer.requestAuthorization()
                showMicrophonePermission = true
                return
            }
            
            // Kaydı başlat/durdur
            speechRecognizer.toggleRecording()
        }) {
            ZStack {
                // Buton arka planı
                Circle()
                    .fill(
                        speechRecognizer.isRecording
                        ? LinearGradient(
                            colors: [AppColors.moodPink, AppColors.moodPeach],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: speechRecognizer.isRecording
                        ? AppColors.moodPink.opacity(0.5)
                        : AppColors.primary.opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                
                // Kayıt sırasında pulse animasyonu
                if speechRecognizer.isRecording {
                    Circle()
                        .stroke(AppColors.moodPink.opacity(0.3), lineWidth: 2)
                        .frame(width: 60, height: 60)
                        .scaleEffect(animateGradient ? 1.2 : 1.0)
                        .opacity(animateGradient ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: animateGradient
                        )
                }
                
                // Mikrofon ikonu (kayıt sırasında stop ikonu)
                Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .scaleEffect(speechRecognizer.isRecording ? 0.8 : 1.0)
            }
        }
        .onAppear {
            if speechRecognizer.isRecording {
                animateGradient = true
            }
        }
        .onChange(of: speechRecognizer.isRecording) { oldValue, newValue in
            animateGradient = newValue
        }
    }
    
    // MARK: - Functions
    // Bugünkü entry'yi kontrol eden fonksiyon
    private func checkTodayEntry() {
        let entries = StorageService.shared.fetchAllEntries()
        
        print("🔍 Toplam entry sayısı: \(entries.count)")
        
        // Bugünün entry'sini bul
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        todayEntry = entries.first { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            let isToday = entryDay == today
            print("🔍 Entry tarihi: \(entry.date) - Bugün mü? \(isToday)")
            return isToday
        }
        
        if let entry = todayEntry {
            // Bugünkü entry varsa yükle
            print("📅 Bugünkü entry bulundu!")
            print("📝 Yüklenecek metin: \(entry.text)")
            journalText = entry.text
            isEditingToday = true
        } else {
            // Yoksa temiz başla
            journalText = ""
            isEditingToday = false
            print("📅 Bugünkü entry yok, yeni oluşturulacak")
        }
    }
    
    // AI analizi yapan fonksiyon
    private func analyzeMood() async {
        hideKeyboard()
        isAnalyzing = true
        
        do {
            // Gemini AI'dan analiz iste
            let moodData = try await GeminiService.shared.analyzeMood(text: journalText)
            
            await MainActor.run {
                self.currentMoodData = moodData
                
                print("🔍 todayEntry var mı? \(todayEntry != nil)")
                
                // Entry'yi kaydet veya güncelle
                if let existingEntry = todayEntry {
                    // Bugünkü entry varsa GÜNCELLE
                    print("🔍 GÜNCELLEME moduna giriyor")
                    let updatedEntry = MoodEntry(
                        id: existingEntry.id,
                        date: existingEntry.date, // Tarih değişmesin
                        text: journalText,
                        moodData: moodData
                    )
                    StorageService.shared.updateEntry(updatedEntry)
                    print("✏️ Bugünkü entry güncellendi!")
                } else {
                    // Bugünkü entry yoksa YENİ OLUŞTUR
                    print("🔍 YENİ OLUŞTURMA moduna giriyor")
                    let newEntry = MoodEntry(
                        id: UUID(),
                        date: Date(),
                        text: journalText,
                        moodData: moodData
                    )
                    StorageService.shared.saveEntry(newEntry)
                    print("💾 Yeni entry oluşturuldu!")
                }
                
                self.isAnalyzing = false
                // Sonuç modalını göster
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.showMoodSheet = true
                }
            }
        } catch {
            await MainActor.run {
                self.isAnalyzing = false
            }
            print("Analiz hatası: \(error)")
        }
    }
    
    // MARK: - Supporting Components
    // Cam efektli kart arka planı
    struct GlassmorphicCard: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 28)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
        }
    }
    
    // Animasyonlu gradient arka plan
    struct AnimatedGradientBackground: View {
        @State private var animateGradient = false
        
        var body: some View {
            ZStack {
                AppColors.background
                
                // İlk daire - sol üstten sağ alta hareket ediyor
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.3), AppColors.secondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: animateGradient ? 100 : -100, y: animateGradient ? -100 : 100)
                    .animation(
                        .easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                        value: animateGradient
                    )
                
                // İkinci daire - sağ alttan sol üste hareket ediyor
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.2), AppColors.primary.opacity(0.3)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 350, height: 350)
                    .blur(radius: 100)
                    .offset(x: animateGradient ? -120 : 120, y: animateGradient ? 150 : -150)
                    .animation(
                        .easeInOut(duration: 10)
                        .repeatForever(autoreverses: true),
                        value: animateGradient
                    )
            }
            .onAppear {
                animateGradient = true // Animasyonu başlat
            }
            .ignoresSafeArea()
        }
    }
    
    // Klavyeyi kapat
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

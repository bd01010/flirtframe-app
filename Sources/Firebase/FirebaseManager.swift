import Foundation
import Combine

#if canImport(Firebase)
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseRemoteConfig
import FirebasePerformance
import FirebaseStorage
#endif

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var user: Any? = nil
    @Published var isAuthenticated = false
    
    #if canImport(Firebase)
    @Published var remoteConfig: RemoteConfig
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let performance = Performance.sharedInstance()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    #endif
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        #if canImport(Firebase)
        self.remoteConfig = RemoteConfig.remoteConfig()
        setupRemoteConfig()
        setupAuthStateListener()
        #else
        print("⚠️ Firebase SDK not available - using stub implementation")
        #endif
    }
    
    deinit {
        #if canImport(Firebase)
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        #endif
    }
    
    #if canImport(Firebase)
    private func setupRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600
        remoteConfig.configSettings = settings
        
        remoteConfig.setDefaults([
            "openai_api_endpoint": "https://api.openai.com/v1/chat/completions",
            "max_openers_per_photo": 5,
            "vision_model_enabled": true,
            "mlx_model_enabled": false,
            "analytics_batch_size": 50,
            "photo_analysis_timeout": 30,
            "feature_instagram_import": true,
            "feature_history_sync": true
        ])
        
        fetchRemoteConfig()
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
            
            if user != nil {
                self?.syncUserData()
            }
        }
    }
    #endif
    
    func configure() {
        #if canImport(Firebase)
        // FirebaseApp.configure() should be called by FirebaseSetup
        signInAnonymously()
        #else
        print("⚠️ Firebase configure called but SDK not available")
        #endif
    }
    
    func signInAnonymously() {
        #if canImport(Firebase)
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
                print("Anonymous sign-in failed: \(error.localizedDescription)")
            } else if let user = result?.user {
                self?.logEvent("user_signed_in", parameters: [
                    "method": "anonymous",
                    "user_id": user.uid
                ])
            }
        }
        #else
        print("⚠️ Anonymous sign-in not available without Firebase")
        isAuthenticated = false
        #endif
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        #if canImport(Firebase)
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        logEvent("user_signed_in", parameters: [
            "method": "email",
            "user_id": result.user.uid
        ])
        #else
        throw FirebaseError.notAuthenticated
        #endif
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        #if canImport(Firebase)
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        try await createUserDocument(for: result.user)
        logEvent("user_signed_up", parameters: [
            "method": "email",
            "user_id": result.user.uid
        ])
        #else
        throw FirebaseError.notAuthenticated
        #endif
    }
    
    #if canImport(Firebase)
    private func createUserDocument(for user: User) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "created_at": FieldValue.serverTimestamp(),
            "updated_at": FieldValue.serverTimestamp(),
            "preferences": [
                "style": "witty",
                "tone": "casual"
            ]
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
    }
    #endif
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if canImport(Firebase)
        Analytics.logEvent(name, parameters: parameters)
        #else
        print("📊 Event: \(name) \(parameters ?? [:])")
        #endif
    }
    
    func trackPhotoAnalysis(photoId: String, analysisTime: TimeInterval, features: [String]) {
        #if canImport(Firebase)
        let trace = performance.trace(name: "photo_analysis")
        trace?.setValue(analysisTime, forMetric: "analysis_time")
        trace?.setValue(Int64(features.count), forMetric: "feature_count")
        trace?.start()
        
        logEvent("photo_analyzed", parameters: [
            "photo_id": photoId,
            "analysis_time": analysisTime,
            "feature_count": features.count,
            "features": features.joined(separator: ",")
        ])
        
        trace?.stop()
        #else
        print("📸 Photo analyzed: \(photoId), time: \(analysisTime)s, features: \(features.count)")
        #endif
    }
    
    func trackOpenerGeneration(photoId: String, count: Int, generationTime: TimeInterval, style: String) {
        #if canImport(Firebase)
        let trace = performance.trace(name: "opener_generation")
        trace?.setValue(generationTime, forMetric: "generation_time")
        trace?.setValue(Int64(count), forMetric: "opener_count")
        trace?.start()
        
        logEvent("opener_generated", parameters: [
            "photo_id": photoId,
            "opener_count": count,
            "generation_time": generationTime,
            "style": style
        ])
        
        trace?.stop()
        #else
        print("💬 Openers generated: \(count), time: \(generationTime)s, style: \(style)")
        #endif
    }
    
    func saveGenerationHistory(_ history: GenerationHistory) async throws {
        #if canImport(Firebase)
        guard let user = user as? User, let userId = user.uid else { return }
        
        var data = history.toDictionary()
        data["userId"] = userId
        data["timestamp"] = FieldValue.serverTimestamp()
        
        try await db.collection("generation_history").addDocument(data: data)
        #else
        print("💾 Would save generation history: \(history.id)")
        #endif
    }
    
    func fetchGenerationHistory(limit: Int = 50) async throws -> [GenerationHistory] {
        #if canImport(Firebase)
        guard let user = user as? User, let userId = user.uid else { return [] }
        
        let snapshot = try await db.collection("generation_history")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            GenerationHistory.fromDictionary(doc.data())
        }
        #else
        return []
        #endif
    }
    
    func syncUserData() {
        #if canImport(Firebase)
        guard let user = user as? User, let userId = user.uid else { return }
        
        Task {
            do {
                let userDoc = try await db.collection("users").document(userId).getDocument()
                
                if !userDoc.exists {
                    try await createUserDocument(for: user)
                } else {
                    try await db.collection("users").document(userId).updateData([
                        "updated_at": FieldValue.serverTimestamp(),
                        "last_seen": FieldValue.serverTimestamp()
                    ])
                }
                
                if remoteConfig["feature_history_sync"].boolValue {
                    try await syncLocalHistoryToFirestore()
                }
            } catch {
                Crashlytics.crashlytics().record(error: error)
            }
        }
        #else
        print("⚠️ User data sync not available without Firebase")
        #endif
    }
    
    private func syncLocalHistoryToFirestore() async throws {
        // Implementation to sync Core Data history with Firestore
    }
    
    func uploadAnalyzedPhoto(_ imageData: Data, photoId: String) async throws -> URL {
        #if canImport(Firebase)
        guard let user = user as? User, let userId = user.uid else {
            throw FirebaseError.notAuthenticated
        }
        
        let storageRef = storage.reference()
        let photoRef = storageRef.child("analyzed_photos/\(userId)/\(photoId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await photoRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await photoRef.downloadURL()
        
        return downloadURL
        #else
        throw FirebaseError.notAuthenticated
        #endif
    }
    
    #if canImport(Firebase)
    func fetchRemoteConfig() {
        remoteConfig.fetch { [weak self] status, error in
            if status == .success {
                self?.remoteConfig.activate { _, _ in
                    self?.logEvent("remote_config_fetched")
                }
            } else if let error = error {
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
    #endif
    
    func recordAnalyticsEvent(_ event: AnalyticsEvent) async throws {
        #if canImport(Firebase)
        guard let user = user as? User, let userId = user.uid else { return }
        
        var eventData = event.toDictionary()
        eventData["userId"] = userId
        eventData["timestamp"] = FieldValue.serverTimestamp()
        
        try await db.collection("analytics_events").addDocument(data: eventData)
        #else
        print("📊 Analytics event: \(event.name)")
        #endif
    }
}

enum FirebaseError: LocalizedError {
    case notAuthenticated
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .syncFailed:
            return "Failed to sync data with Firebase"
        }
    }
}

struct GenerationHistory {
    let id: String
    let photoId: String
    let openers: [String]
    let style: String
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "photoId": photoId,
            "openers": openers,
            "style": style
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> GenerationHistory? {
        guard let photoId = data["photoId"] as? String,
              let openers = data["openers"] as? [String],
              let style = data["style"] as? String else {
            return nil
        }
        
        #if canImport(Firebase)
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        #else
        let timestamp = Date()
        #endif
        
        return GenerationHistory(
            id: UUID().uuidString,
            photoId: photoId,
            openers: openers,
            style: style,
            timestamp: timestamp
        )
    }
}

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "parameters": parameters
        ]
    }
}
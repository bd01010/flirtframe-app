import SwiftUI
import AVFoundation
import Photos

struct CameraScreen: View {
    @StateObject private var camera = CameraModel()
    @State private var capturedImage: UIImage?
    @State private var showingAnalysis = false
    @State private var analysisResult: AnalysisResult?
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingPermissionAlert = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    // Gallery button
                    Button(action: openGallery) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Capture button
                    Button(action: capturePhoto) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(Color.white, lineWidth: 5)
                                .frame(width: 90, height: 90)
                        }
                    }
                    .disabled(isProcessing)
                    
                    // Switch camera button
                    Button(action: { camera.switchCamera() }) {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 30)
            }
            
            if isProcessing {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                ProgressView("Analyzing photo...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            camera.checkPermissions { granted in
                if !granted {
                    self.showingPermissionAlert = true
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable camera access in Settings to capture photos.")
        }
        .sheet(isPresented: $showingAnalysis) {
            if let result = analysisResult, let image = capturedImage {
                OpenerResultView(
                    image: image,
                    result: result,
                    onGenerateMore: { generateMoreOpeners(for: result) },
                    onDismiss: { showingAnalysis = false }
                )
            }
        }
    }
    
    private func capturePhoto() {
        camera.capturePhoto { image in
            self.capturedImage = image
            if let image = image {
                analyzePhoto(image)
            } else {
                self.errorMessage = "Failed to capture photo. Please try again."
                self.showingError = true
            }
        }
    }
    
    private func openGallery() {
        // TODO: Implement gallery picker
        self.errorMessage = "Gallery feature coming soon!"
        self.showingError = true
    }
    
    private func analyzePhoto(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let analyzer = PhotoAnalyzer()
                let result = try await analyzer.analyze(image: image)
                
                await MainActor.run {
                    self.analysisResult = result
                    self.isProcessing = false
                    self.showingAnalysis = true
                    
                    // Track usage
                    appState.trackAnalysis()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = "Failed to analyze photo. Please try again."
                    self.showingError = true
                }
            }
        }
    }
    
    private func generateMoreOpeners(for result: AnalysisResult) {
        // Implementation for generating additional openers
    }
}

class CameraModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var output = AVCapturePhotoOutput()
    
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var position: AVCaptureDevice.Position = .back
    
    deinit {
        session.stopRunning()
    }
    
    func checkPermissions(completion: ((Bool) -> Void)? = nil) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            completion?(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setUp()
                    }
                    completion?(granted)
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                completion?(false)
            }
        @unknown default:
            DispatchQueue.main.async {
                completion?(false)
            }
        }
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            // Get camera device
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
                self.device = device
                let input = try AVCaptureDeviceInput(device: device)
                
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.input = input
                }
                
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                }
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func switchCamera() {
        position = position == .back ? .front : .back
        
        session.beginConfiguration()
        
        // Remove existing input
        if let input = self.input {
            session.removeInput(input)
        }
        
        // Add new input
        do {
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
                self.device = device
                let newInput = try AVCaptureDeviceInput(device: device)
                
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                    self.input = newInput
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        session.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        
        output.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
}

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.completion(image)
            }
        } else {
            DispatchQueue.main.async {
                self.completion(nil)
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        DispatchQueue.main.async {
            if camera.preview == nil {
                camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
            }
            camera.preview.frame = view.frame
            camera.preview.videoGravity = .resizeAspectFill
            
            // Remove any existing preview layers
            view.layer.sublayers?.forEach { sublayer in
                if sublayer is AVCaptureVideoPreviewLayer {
                    sublayer.removeFromSuperlayer()
                }
            }
            
            view.layer.addSublayer(camera.preview)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            camera.preview?.frame = uiView.bounds
        }
    }
}
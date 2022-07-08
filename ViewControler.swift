class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{
    
    
    let session = AVCaptureSession()
    let output = AVCaptureMovieFileOutput()
    var input : AVCaptureDeviceInput!
    var outputUrl: URL!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.check()
    }
    @IBAction func BtnTapped(_ sender: Any) {
        work()
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print("Error: \(error!.localizedDescription)")
        } else{
            UISaveVideoAtPathToSavedPhotosAlbum(outputUrl.path, nil, nil, nil)
            print("Done")
        }
    }
    
    
    private func check(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            self.setup()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setup()
                }
            }
        case .denied:
            return
        case .restricted:
            return
        @unknown default:
           return
        }
    }
    
    private func setup(){
        self.session.beginConfiguration()
        let device = bestDevice(in: .back)
        guard
            let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input)
        else{return}
        self.session.addInput(input)
        self.input = input
        
        guard
            self.session.canAddOutput(self.output) else {return}
        self.session.sessionPreset = .high
        self.session.addOutput(self.output)
        self.session.commitConfiguration()
    }
    
    private func bestDevice(in position: AVCaptureDevice.Position) -> AVCaptureDevice{
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInUltraWideCamera], mediaType: .video, position: position).devices
        guard
            !devices.isEmpty else{ fatalError("No device found")}
        return devices.first!
    }
    
    
    private func start(){
        if(!self.session.isRunning){
            getQueue().async {
                self.session.startRunning()
                self.output.startRecording(to: self.outputUrl, recordingDelegate: self)
            }
        }
    }
    
    private func stop(){
        if(self.session.isRunning){
            getQueue().async {
                self.output.stopRecording()
                self.session.stopRunning()
            }
        }
    }
    private func getQueue() -> DispatchQueue{
        return DispatchQueue.main
    }
    
    
    
    private func work(){
        if !self.output.isRecording {
            let conn = self.output.connection(with: .video)
            if (conn?.isVideoStabilizationSupported)!{
                conn?.preferredVideoStabilizationMode = .auto
            }
            let device = input.device
            if(device.isSmoothAutoFocusSupported){
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    fatalError()
                }
            }
            self.outputUrl = generateUrl()
            start()
        } else{
            stop()
        }
    }
    
    private func generateUrl() -> URL?{
        let dir = NSTemporaryDirectory() as NSString
        if dir != ""{
            let path = dir.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}

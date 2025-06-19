//
//  CameraViewController.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 09/06/25.
//

import AVFoundation
import UIKit

class CameraViewController: UIViewController {
    private let viewModel: CameraViewModel
    private let previewLayer: AVCaptureVideoPreviewLayer
    
    init(viewModel: CameraViewModel){
        self.viewModel = viewModel
        self.previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.captureSession)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
}

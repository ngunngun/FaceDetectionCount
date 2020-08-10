//
//  ViewController.swift
//  FaceDetectionCount
//
//  Created by Kirameki on 10/8/2563 BE.
//  Copyright © 2563 ngunngun. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureDevice: AVCaptureDevice?
    var textLabel = UILabel()
    var isShowFrontCamera = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpCamera(cameraPosition: .front) //default position = .front
        self.setUpTextLabel()
        self.view.backgroundColor = .white
    }

    func setUpChangeCameraPositionButton() {
        let button = UIButton()
        button.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        button.frame = CGRect(x: 16, y: 16, width: 60, height: 60)
        button.addTarget(self, action: #selector(self.switchCameraPosition), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    func setUpTextLabel() {
        self.textLabel.text = "0"
        self.textLabel.textColor = .black
        self.textLabel.textAlignment = .right
        self.textLabel.frame = CGRect(x: 16, y: 16, width: self.view.frame.width - 32, height: 60)
        self.view.addSubview(self.textLabel)
    }
    
    func setUpCamera(cameraPosition: AVCaptureDevice.Position) {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard var captureDevice = AVCaptureDevice.default(for: .video) else { return }
        captureDevice = self.cameraWithPosition(position: cameraPosition)!
        self.captureDevice = captureDevice
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = CGRect(x: 0, y: 80, width: self.view.frame.width, height: self.view.frame.height - 96) //view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        self.setUpChangeCameraPositionButton()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceRectanglesRequest { (req, err) in
            if let err = err {
                print("Error:", err)
                return
            }
            DispatchQueue.main.async {
                if let results = req.results {
                    self.textLabel.text = "found \(results.count) face(s)"
                }
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch let reqErr {
                print("Request failed:", reqErr)
            }
        }
    }
    
    @objc func switchCameraPosition() {
        self.isShowFrontCamera = !self.isShowFrontCamera
        self.setUpCamera(cameraPosition: self.isShowFrontCamera ? .front : .back)
    }
    
    //Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}


//
//  ViewController.swift
//  MachineLearningImageRecongition
//
//  Created by Matteo Buompastore on 05/05/23.
//

import UIKit
import Photos
import PhotosUI
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    var chosenImage = CIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func changeClicked(_ sender: Any) {
        openPHPicker()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        self.dismiss(animated: true)
    }
    
    func recogniseImage(image : UIImage?) {
        if let ciImage = CIImage(image: image!) {
            chosenImage = ciImage
        }
        
        if let model = try? VNCoreMLModel(for: MobileNetV2().model) {
            let request = VNCoreMLRequest(model: model) { vnRequest, err in
                if(err != nil) {
                    print("Error in ML")
                    return
                }
                
                if let results = vnRequest.results as? [VNClassificationObservation] {
                    if results.isEmpty {
                        return
                    }
                    
                    let topResult = results.first!
                    
                    DispatchQueue.main.async {
                        
                        let confidenceLevel = topResult.confidence * 100
                        let roundedConfidence = Int(confidenceLevel * 100) / 100
                        
                        self.resultLabel.text = "\(roundedConfidence)% it's \(topResult.identifier)"
                    }
                }
                
            }
            let handler = VNImageRequestHandler(ciImage: chosenImage)
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Error")
                }
                
            }
        }
    }
    
}

// MARK: - PHPicker Configurations (PHPickerViewControllerDelegate)
extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: .none)
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                guard let image = reading as? UIImage, error == nil else { return }
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.recogniseImage(image: image)
                }
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { [weak self] url, _ in
                    // TODO: - Here You Get The URL
                }
            }
        }
    }
    
    /// call this method for `PHPicker`
       func openPHPicker() {
           print("Open picker!")
           var phPickerConfig = PHPickerConfiguration(photoLibrary: .shared())
           phPickerConfig.selectionLimit = 1
           phPickerConfig.filter = PHPickerFilter.any(of: [.images, .livePhotos])
           let phPickerVC = PHPickerViewController(configuration: phPickerConfig)
           phPickerVC.delegate = self
           present(phPickerVC, animated: true)
       }
}

//
//  MLLayer.swift
//  HelloContentul
//
//  Created by Cyril Garcia on 12/8/20.
//

import UIKit
import Vision

protocol MLLayerDelegate: AnyObject {
    func didFinishTaggingImage(_ tags: Set<String>)
}

final class MLLayer {
    
    weak var delegate: MLLayerDelegate?
    
    func tag(_ image: UIImage) {
        do {
//            prepare the model
            let config = MLModelConfiguration()
            let model = try YOLOv3(configuration: config)
            let visionModel = try VNCoreMLModel(for: model.model)
            
//            analyze the image
            let objectRecognition = VNCoreMLRequest(model: visionModel) { (request, error) in
                if let results = request.results {
                    self.parseResults(results)
                }
            }
            
//            pass the image to analyze
            let imageRequestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            try imageRequestHandler.perform([objectRecognition])
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
//    get the results
    func parseResults(_ results: [Any]) {
        
        var tags = Set<String>()
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            let topLabelObservation = objectObservation.labels[0]
            tags.insert(topLabelObservation.identifier)
        }
        
        DispatchQueue.main.async {
            self.delegate?.didFinishTaggingImage(tags)
        }
        
    }
}

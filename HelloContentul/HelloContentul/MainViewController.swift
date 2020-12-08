//
//  MainViewController.swift
//  HelloContentul
//
//  Created by Cyril Garcia on 12/4/20.
//

import UIKit

class MainViewController: UIViewController, MLLayerDelegate, NetworkLayerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleField: UITextField!
    @IBOutlet var subtitleField: UITextField!
    @IBOutlet var tagsField: UITextField!
    @IBOutlet var contentView: UITextView!
        
    let networkLayer = NetworkLayer()
    let mlLayer = MLLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        mlLayer.delegate = self
        networkLayer.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(askForImageURL))
        tapGesture.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func done() {
        let fields = Fields(title: titleField.text!,
                            subtitle: subtitleField.text!,
                            tags: tagsField.text!,
                            content: contentView.text!)
        let article = Article(fields: fields)
        
        networkLayer.post(article)
    }
    
    @objc
    func askForImageURL() {
        let alert = UIAlertController(title: "Image URL", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "URL"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let add = UIAlertAction(title: "Add", style: .default) { [weak self] (_) in
            guard let url = alert.textFields?.first?.text else { return }
            self?.networkLayer.getImage(from: url)
        }
        
        alert.addAction(add)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func didFinishTaggingImage(_ tags: Set<String>) {
        tagsField.text = tags.joined(separator: ",")
    }
    
    func didFinishGettingImage(_ image: UIImage) {
        imageView.image = image
        mlLayer.tag(image)
    }

    func didFinishProcessingImage() {
        let alert = UIAlertController(title: "Finished Tagging Image", message: nil, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
        
        alert.addAction(okay)
        
        present(alert, animated: true, completion: nil)
    }
    
    func didFinishCreatingAsset() {
        let alert = UIAlertController(title: "Entry is ready!", message: "Do you want to publish it?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let publish = UIAlertAction(title: "Publish", style: .default) { [weak self] (_) in
            self?.networkLayer.publishEntry()
        }
        
        alert.addAction(publish)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func didFinishPublishingEntry() {
        let alert = UIAlertController(title: "Entry Published!", message: nil, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
        
        alert.addAction(okay)
        
        present(alert, animated: true, completion: nil)
    }
    
}

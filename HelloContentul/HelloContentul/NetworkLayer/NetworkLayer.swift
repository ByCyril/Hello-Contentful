//
//  NetworkLayer.swift
//  HelloContentul
//
//  Created by Cyril Garcia on 12/8/20.
//

import UIKit

protocol NetworkLayerDelegate: AnyObject {
    func didFinishGettingImage(_ image: UIImage)
    func didFinishProcessingImage()
    func didFinishCreatingAsset()
    func didFinishPublishingEntry()
}

struct Article: Codable {
    var fields: Fields
}

struct Fields: Codable {
    var title: [String: String]
    var subtitle: [String: String]
    var tags: [String: String]
    var content: [String: String]
    var image: [String: [String : [String : String]]]?
    
    init(title: String, subtitle: String, tags: String, content: String) {
        self.title = ["en-US": title]
        self.subtitle = ["en-US": subtitle]
        self.tags = ["en-US": tags]
        self.content = ["en-US": content]
    }
    
}

final class NetworkLayer {
    
    private var sessions: URLSession?
    private var assetId: String?
    private var entryId: String?
    
    private let spaces = "w4ctznsnjumx"
    private let env = "master"
    private let auth = "Bearer CFPAT-l0TujDsHSlCib8MOnftiWzHrbiwjfUY7CBzuQo-ULKk"

    weak var delegate: NetworkLayerDelegate?
    
    init() {
        configureURLSessions()
    }

    func configureURLSessions() {
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.urlCredentialStorage = nil
        config.httpCookieStorage = .none
        config.httpCookieAcceptPolicy = .never
        
        sessions = URLSession(configuration: config)
    }
    
    func getImage(from url: String) {
        let imageUrl = URL(string: url)!
        
        sessions?.dataTask(with: imageUrl, completionHandler: {(data, response, error) in
            guard let image = UIImage(data: data!) else { return }
            
            DispatchQueue.main.async {
                self.delegate?.didFinishGettingImage(image)
                self.createAsset(with: imageUrl)
            }
        }).resume()
        
    }
    
    func post(_ article: Article) {
        var article = article
        article.fields.image = ["en-US": ["sys":["type": "Link","linkType": "Asset","id": assetId!]]]
        publishAsset(with: article)
    }
    
    private func createAsset(with imageUrl: URL) {
        let url = URL(string: "https://api.contentful.com/spaces/\(spaces)/environments/\(env)/assets")!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/vnd.contentful.management.v1+json", forHTTPHeaderField: "Content-Type")
        request.addValue(auth, forHTTPHeaderField: "Authorization")
                
        let body = ["fields": [
                        "title": ["en-US": imageUrl.lastPathComponent],
                        "file": [ "en-US": [
                                "contentType": "image/\(imageUrl.pathExtension)",
                                "fileName": imageUrl.lastPathComponent,
                                "upload": imageUrl.absoluteString]]]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = jsonData
        
        sessions?.dataTask(with: request, completionHandler: { (data, response, error) in

            if let error = error {
                print(error.localizedDescription)
            } else {
                let jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject]
                let assetId = (jsonData!["sys"] as! [String: Any])["id"] as! String
                self.processAsset(assetId)
            }
            
        }).resume()
    }
    
    private func processAsset(_ assetId: String) {
        let url = URL(string: "https://api.contentful.com/spaces/\(spaces)/environments/\(env)/assets/\(assetId)/files/en-US/process")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "PUT"
        request.addValue("1", forHTTPHeaderField: "X-Contentful-Version")
        request.addValue(auth, forHTTPHeaderField: "Authorization")

        sessions?.dataTask(with: request, completionHandler: { (data, response, error) in

            if let error = error {
                print(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self.assetId = assetId
                    self.delegate?.didFinishProcessingImage()
                }
            }
            
        }).resume()
    }
    
    private func publishAsset(with article: Article) {
        
        let url = URL(string: "https://api.contentful.com/spaces/\(spaces)/environments/\(env)/assets/\(assetId!)/published")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "PUT"
        request.addValue("2", forHTTPHeaderField: "X-Contentful-Version")
        request.addValue(auth, forHTTPHeaderField: "Authorization")

        sessions?.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.createEntry(with: article)
            }
            
        }).resume()
    }
    
    private func createEntry(with article: Article?) {
        let url = URL(string: "https://api.contentful.com/spaces/\(spaces)/environments/\(env)/entries")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(auth,
                         forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.contentful.management.v1+json",
                         forHTTPHeaderField: "Content-Type")
        request.addValue("article",
                         forHTTPHeaderField: "X-Contentful-Content-Type")

        guard let jsonData = try? JSONEncoder().encode(article) else { return }
        request.httpBody = jsonData
        
        sessions?.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else {
                let jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject]
                let entryId = (jsonData!["sys"] as! [String: Any])["id"] as! String
                
                DispatchQueue.main.async {
                    self.entryId = entryId
                    self.delegate?.didFinishCreatingAsset()
                }
            }
            
        }).resume()
    }
    
    func publishEntry() {
        
        let url = URL(string: "https://api.contentful.com/spaces/\(spaces)/environments/\(env)/entries/\(entryId!)/published")!

        var request = URLRequest(url: url)
        
        request.httpMethod = "PUT"
        request.addValue("1", forHTTPHeaderField: "X-Contentful-Version")
        request.addValue(auth, forHTTPHeaderField: "Authorization")
        
        sessions?.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self.delegate?.didFinishPublishingEntry()
                }
            }
        }).resume()
    }
    
}

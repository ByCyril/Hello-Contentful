//
//  Model.swift
//  HelloContentul
//
//  Created by Cyril Garcia on 12/8/20.
//

import Foundation

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

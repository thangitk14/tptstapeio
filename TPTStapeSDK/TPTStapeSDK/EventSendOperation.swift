//
//  EventSendOperation.swift
//  StapeSDK
//
//  Created by Deszip on 15.10.2023.
//  Copyright © 2023 Stape. All rights reserved.
//

import Foundation

class EventSendOperation: Operation {
    
    var queue: EventQueue?
    
    private var processing: Bool {
        willSet {
            willChangeValue(forKey: "isFinished")
            willChangeValue(forKey: "isExecuting")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    let operationUUID: String
    override var isFinished: Bool { return !processing }
    override var isExecuting: Bool { return processing }
    
    private let config: TPTStape.Configuration
    private let event: TPTStape.Event
    private var completion: TPTStape.Completion?
    
    init(config: TPTStape.Configuration, event: TPTStape.Event, completion: TPTStape.Completion? = nil) {
        self.processing = false
        self.operationUUID = NSUUID().uuidString
        self.config = config
        self.event = event
        self.completion = completion
        
        super.init()
    }
    
    override func start() {
        if isCancelled { return }
        processing = true
        
        guard let request = self.buildRequest() else {
            self.finish()
            return
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                TPTStape.logger.warning("Response error: \(String(describing: error))")
                self.completion?(.failure(.networkFailure(error)))
                return
            }

            do {
                if let data = data {
                    if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                        self.completion?(.success(TPTStape.EventResponse(payload: result)))
                    } else {
                        TPTStape.logger.warning("Failed to cast serialized response")
                        self.completion?(.failure(.serializationFailure))
                    }
                } else {
                    TPTStape.logger.warning("No data in response")
                    self.completion?(.failure(.noData))
                }
            } catch {
                TPTStape.logger.warning("Response serialization error: \(error)")
                self.completion?(.failure(.serializationFailure))
            }
            
            self.finish()
        })

        task.resume()
    }
    
    override func cancel() {
        finish()
    }
    
    func finish() { processing = false }
    
    private func    buildRequest() -> URLRequest? {
        guard let url = URL(string: self.config.domain.absoluteString.appending(self.config.endpoint)),
              var comps = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        comps.queryItems = [
            URLQueryItem(name: "v", value: self.config.protocolVersion),
            URLQueryItem(name: "event_name", value: self.event.name),
            URLQueryItem(name: "richsstsse", value: self.config.richsstsse ? "true" : "false")
        ]
        
        guard let fullURL = comps.url else {
            return nil
        }
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("ios-sdk", forHTTPHeaderField: "stape-client-id")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self.event.payload, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            TPTStape.logger.warning("Failed to encode payload: \(error)")
            return nil
        }
        
        return request
    }
}

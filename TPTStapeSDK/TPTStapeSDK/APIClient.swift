//
//  APIClient.swift
//  StapeSDK
//
//  Created by Deszip on 15.10.2023.
//  Copyright © 2023 Stape. All rights reserved.
//

import Foundation

class APIClient {
    
    private let queue: OperationQueue
    private var eventBuffer: [TPTStape.Event]
    
    var config: TPTStape.Configuration? { didSet { self.flush() } }
    
    init() {
        self.queue = OperationQueue()
        self.eventBuffer = []
    }
    
    public func send(event: TPTStape.Event, completion: TPTStape.Completion? = nil) {
        if let config = self.config {
            let op = EventSendOperation(config: config, event: event, completion: completion)
            self.queue.addOperation(op)
        } else {
            self.eventBuffer.append(event)
        }
    }
    
    private func flush() {
        self.eventBuffer.forEach { self.send(event: $0) }
    }
    
}

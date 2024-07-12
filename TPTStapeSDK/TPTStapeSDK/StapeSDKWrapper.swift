//
//  Stape.swift
//  StapeSDK
//
//  Created by Deszip on 15.10.2023.
//  Copyright © 2023 Stape. All rights reserved.
//

import Foundation
import os

// Define an Objective-C compatible error enum
@objc public enum SendError: Int, Error {
    case networkFailure
    case serializationFailure
    case noData
}

@objc(StapeSDKWrapper)
public class StapeSDKWrapper: NSObject {
    
    public typealias CompletionHandler = (EventResponse?, NSError?) -> Void

    // Models
    @objc public class Configuration : NSObject {
        let domain: URL
        let endpoint: String
        let richsstsse: Bool
        let protocolVersion: String
        
        @objc public init(domain: URL) {
            self.domain = domain
            self.endpoint = "/data"
            self.richsstsse = false
            self.protocolVersion = "2"
        }
        
        @objc public init(domain: URL, endpoint: String = "/data", richsstsse: Bool = false, protocolVersion: String = "2") {
            self.domain = domain
            self.endpoint = endpoint
            self.richsstsse = richsstsse
            self.protocolVersion = protocolVersion
        }
    }
    
    @objc public class Event : NSObject {
        public enum Key: String {
            case clientID       = "client_id"
            // Pls check Apple docs on IDFA:
            // https://developer.apple.com/documentation/apptrackingtransparency?language=objc
            case idfa           = "idfa"
            case currency       = "currency"
            case ipOverride     = "ip_override"
            case language       = "language"
            case pageEncoding   = "page_encoding"
            case pageHostname   = "page_hostname"
            case pageLocation   = "page_location"
            case pagePath       = "page_path"
        }
        
        public let name: String
        public let payload: [String: AnyHashable]
        
        @objc public init(name: String, payload: [String : AnyHashable] = [:]) {
            self.name = name
            self.payload = payload
        }
        
        public init(name: String, payload: [Key : AnyHashable] = [:]) {
            self.name = name
            self.payload = Dictionary(uniqueKeysWithValues: payload.map { ($0.key.rawValue, $0.value) })
        }
    }
    
    @objc public class EventResponse: NSObject {
        public var payload: [String: AnyObject] = [:]
        public init(payload: [String: AnyObject]) {
            self.payload = payload
        }
    }
    
    // SDK State
    public enum State {
        case running(Configuration)
        case idle
        
        func handleStart(_ stape: StapeSDKWrapper, configuration: Configuration) -> State {
            stape.apiCLient.config = TPTStape.Configuration(domain: configuration.domain)
            return .running(configuration)
        }
        
        
        func handleEvent(_ stape: StapeSDKWrapper, event: Event, completion: CompletionHandler? = nil) -> State {
            guard case .running = self else { return self }

            let eventToSend = TPTStape.Event(name: event.name, payload: event.payload)

            stape.apiCLient.send(event: eventToSend) { result in
                switch result {
                case .success(let response):
                    let eventResponse = EventResponse(payload: response.payload);
                    completion?(eventResponse, nil)
                case .failure(let error):
                    completion?(nil, error as NSError)
                }
            }

            return self
        }
    }
    
    private static var shared: StapeSDKWrapper = { return StapeSDKWrapper(apiCLient: APIClient()) }()
    
    static let logger = Logger(subsystem: "com.stape.logger", category: "main")
    private var state: State = .idle
    private let apiCLient: APIClient
        
    init(apiCLient: APIClient) {
        self.state = .idle
        self.apiCLient = apiCLient
    }
    
    // MARK: - Public API
    
    @objc public static func start(configuration: Configuration) {
        shared.start(configuration: configuration)
    }
    
    @objc public static func send(event: Event, completion: CompletionHandler? = nil) {
        shared.send(event: event, completion: completion)
    }
    
    private func start(configuration: Configuration) {
        state = state.handleStart(self, configuration: configuration)
    }
    
    private func send(event: Event, completion: CompletionHandler? = nil) {
        state = state.handleEvent(self, event: event, completion: completion)
    }
}

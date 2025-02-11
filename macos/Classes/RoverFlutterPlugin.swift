
#if canImport(Cocoa)
import Cocoa
import FlutterMacOS
#endif

#if canImport(UIKit)
import Flutter
import UIKit
#endif

import RoveriOS

public typealias ResponseBlock = (String?, String?) -> ()

fileprivate func rerror(_ result: @escaping FlutterResult, _ error: String) {
    return result(FlutterError(code: "Rover Error", message: error, details: nil))
}

public class RoverFlutterPlugin: NSObject, FlutterPlugin {
    
    private var delegates: [String: NativeRoverDelegate] = [:]
    private let channel: FlutterMethodChannel
    
    private var waitingForResponseFromDelegate: [String: ResponseBlock] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
#if canImport(Cocoa)
        let channel = FlutterMethodChannel(name: "smallplanet.com/rover_flutter", binaryMessenger: registrar.messenger)
        let instance = RoverFlutterPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
#endif
#if canImport(UIKit)
        let channel = FlutterMethodChannel(name: "smallplanet.com/rover_flutter", binaryMessenger: registrar.messenger())
        let instance = RoverFlutterPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
#endif
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func remove(delegateUUID: String) {
       delegates[delegateUUID] = nil
   }
    
    public func send(_ delegateUUID: String,
                     _ argsJson: String,
                     _ returnCallback: @escaping ResponseBlock) {
        waitingForResponseFromDelegate[delegateUUID] = returnCallback
        channel.invokeMethod("callDelegate", arguments: ["delegateUUID": delegateUUID, "argsJson": argsJson])
    }
    
    public func handle(_ call: FlutterMethodCall,
                       result: @escaping FlutterResult) {
        switch call.method {
        case "version":
            result(Rover.shared.version)
        case "coreVersion":
            result(Rover.shared.coreVersion)
        case "configure":
            configure(call, result: result)
        case "featureFlags":
            featureFlags(call, result: result)
        case "collect":
            collect(call, result: result)
        case "cancel":
            cancel(call, result: result)
        case "cancelAll":
            cancelAll(call, result: result)
        case "preconfig":
            preconfig(call, result: result)
        case "connections":
            connections(call, result: result)
        case "remove":
            remove(call, result: result)
        case "sendResult":
            sendResult(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func sendResult(_ call: FlutterMethodCall,
                    result: @escaping FlutterResult) {
        struct Args: Codable {
            var delegateUUID: String
            var resultJson: String?
            var resultError: String?
        }
        guard let argsJson = call.arguments as? String else {
            return rerror(result, "rover method called with non-String argument")
        }
        guard let args: Args = try? argsJson.decoded() else {
            return rerror(result, argsJson.decodedError(Args.self))
        }
        
        guard let pendingResult = waitingForResponseFromDelegate[args.delegateUUID] else {
            return
        }
        waitingForResponseFromDelegate[args.delegateUUID] = nil

        pendingResult(args.resultJson, args.resultError)

        return result(nil)
    }
    
    func featureFlags(_ call: FlutterMethodCall,
                      result: @escaping FlutterResult) {
        guard let resultJson = try? Rover.shared.featureFlags.json() else {
            return rerror(result, "Failed to serialize feature flags")
        }
        return result(resultJson)
    }
    
    func configure(_ call: FlutterMethodCall,
                   result: @escaping FlutterResult) {
        struct Args: Codable {
            var licenseKey: String
            var environment: String
            var deviceId: String?
            var maxConcurrentCollections: Int?
        }
        guard let argsJson = call.arguments as? String else {
            return rerror(result, "rover method called with non-String argument")
        }
        guard let args: Args = try? argsJson.decoded() else {
            return rerror(result, argsJson.decodedError(Args.self))
        }
        guard let roverEnvironment = Rover.Environment(rawValue: args.environment) else {
            return rerror(result, "Unknown environment: \(args.environment)")
        }
        Rover.shared.configure(licenseKey: args.licenseKey,
                               environment: roverEnvironment,
                               deviceId: args.deviceId ?? "unknown",
                               maxConcurrentCollections: args.maxConcurrentCollections ?? 4) { merchants, error in
            if let error = error {
                return rerror(result, error)
            }
            guard let resultJson = try? merchants.json() else {
                return rerror(result, "Failed to serialize merchants")
            }
            return result(resultJson)
        }
    }
    
    func collect(_ call: FlutterMethodCall,
                 result: @escaping FlutterResult) {
        struct Args: Codable {
            var delegateUUID: String?
            var userId: String?
            var account: String?
            var password: String?
            var cookiesBase64: String?
            var merchantId: Int
            var javascript: Data?
            var javascriptUrl: String?
            var javascriptVersion: Int?
            var fromDate: Date
            var toDate: Date?
            var tier1BatchSize: Int?
            var tier2BatchSize: Int?
            var tier3BatchSize: Int?
            var receiptsBatchSize: Int?
            var collectItemInfo: Bool?
            var collectSourceData: Bool?
            var isEphemeral: Bool?
            var hasBackend: Bool?
            var allowUserInteractionRequired: Bool?
            var appInfo: String?
            var featureFlags: [String]?
            var overrideMimicDesktopIfPossible: Bool?
            var overrideWebviewBlockImageLoading: Bool?
        }
        guard let argsJson = call.arguments as? String else {
            return rerror(result, "rover method called with non-String argument")
        }
        guard let args: Args = try? argsJson.decoded() else {
            return rerror(result, argsJson.decodedError(Args.self))
        }
        guard let delegateUUID = args.delegateUUID else {
            return rerror(result, "missing delegate uuid")
        }
        guard delegateUUID.isEmpty == false else {
            return rerror(result, "invalid delegate uuid")
        }
        guard delegates[delegateUUID] == nil else {
            return rerror(result, "delegateUUID \(delegateUUID) already exists")
        }
        
        let delegate = NativeRoverDelegate(uuid: delegateUUID,
                                           roverFlutterPlugin: self)
        
        delegates[delegateUUID] = delegate
        
        Rover.shared.collect(userId: args.userId,
                             account: args.account,
                             password: args.password,
                             cookiesBase64: args.cookiesBase64,
                             merchantId: args.merchantId,
                             javascript: args.javascript,
                             javascriptUrl: args.javascriptUrl,
                             javascriptVersion: args.javascriptVersion,
                             fromDate: args.fromDate,
                             toDate: args.toDate,
                             serviceGroupRequests: nil,
                             tier1BatchSize: args.tier1BatchSize ?? 16,
                             tier2BatchSize: args.tier2BatchSize ?? 16,
                             tier3BatchSize: args.tier3BatchSize ?? 16,
                             receiptsBatchSize: args.receiptsBatchSize ?? 8,
                             collectItemInfo: args.collectItemInfo ?? false,
                             collectSourceData: args.collectSourceData ?? false,
                             isEphemeral: args.isEphemeral ?? false,
                             hasBackend: args.hasBackend ?? false,
                             allowUserInteractionRequired: args.allowUserInteractionRequired ?? true,
                             appInfo: args.appInfo,
                             featureFlags: args.featureFlags,
                             overrideMimicDesktopIfPossible: args.overrideMimicDesktopIfPossible,
                             overrideWebviewBlockImageLoading: args.overrideWebviewBlockImageLoading,
                             delegate: delegate)
        result(nil)
    }
    
    func cancel(_ call: FlutterMethodCall,
                result: @escaping FlutterResult) {
        struct Args: Codable {
            var sessionUUID: String
        }
        guard let argsJson = call.arguments as? String else {
            return rerror(result, "rover method called with non-String argument")
        }
        guard let args: Args = try? argsJson.decoded() else {
            return rerror(result, argsJson.decodedError(Args.self))
        }
        Rover.shared.cancel(sessionUUID: args.sessionUUID) { (error) in
            if let error = error {
                return rerror(result, error)
            }
            return result(nil)
        }
    }
    
    func cancelAll(_ call: FlutterMethodCall,
                   result: @escaping FlutterResult) {
        Rover.shared.cancelAll() { (error) in
            if let error = error {
                return rerror(result, error)
            }
            return result(nil)
        }
    }
    
    func preconfig(_ call: FlutterMethodCall,
                   result: @escaping FlutterResult) {
        struct Args: Codable {
            var delegateUUID: String?
            var userId: String?
            var merchantId: Int?
            var javascript: Data?
            var javascriptUrl: String?
            var javascriptVersion: Int?
        }
        guard let argsJson = call.arguments as? String else {
            return rerror(result, "rover method called with non-String argument")
        }
        guard let args: Args = try? argsJson.decoded() else {
            return rerror(result, argsJson.decodedError(Args.self))
        }
        guard let delegateUUID = args.delegateUUID else {
            return rerror(result, "missing delegate uuid")
        }
        guard delegateUUID.isEmpty == false else {
            return rerror(result, "invalid delegate uuid")
        }
        guard delegates[delegateUUID] == nil else {
            return rerror(result, "delegateUUID \(delegateUUID) already exists")
        }
        
        let delegate = NativeRoverDelegate(uuid: delegateUUID,
                                           roverFlutterPlugin: self)
                
        Rover.shared.preconfig(userId: args.userId,
                               merchantId: args.merchantId,
                               javascript: args.javascript,
                               javascriptUrl: args.javascriptUrl,
                               javascriptVersion: args.javascriptVersion,
                               delegate: delegate) { resultJson, error in
            if let error = error {
                return rerror(result, error)
            }
            return result(resultJson)
        }
    }
    
    func connections(_ call: FlutterMethodCall,
                     result: @escaping FlutterResult) {
        Rover.shared.connections { connections in
            guard let connectionsJson = try? connections.json() else {
                return rerror(result, "failed to serialize connections")
            }
            return result(connectionsJson)
        }
    }
    
    func remove(_ call: FlutterMethodCall,
                result: @escaping FlutterResult) {
        struct Args: Codable {
            var account: String
            var merchantId: Int
        }
        guard let argsJson = call.arguments as? String else {
            return rerror(result, "rover method called with non-String argument")
        }
        guard let args: Args = try? argsJson.decoded() else {
            return rerror(result, argsJson.decodedError(Args.self))
        }

        Rover.shared.remove(account: args.account,
                            merchantId: args.merchantId) {
            return result(nil)
        }
    }
}

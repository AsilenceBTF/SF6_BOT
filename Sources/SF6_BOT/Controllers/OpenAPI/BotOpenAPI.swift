//
//  BotOpenAPI.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/2.
//
import Vapor

public protocol BotOpenAPI {
    static var shared: any BotOpenAPI { get }
    func sendMessage(content: any Content, msg: String)
}

public class BotOpenAPIManager {
    nonisolated(unsafe) private static var _default: (any BotOpenAPI)?
    public static func configDefault(API: any BotOpenAPI) {
        _default = API
    }
    public static var defaultAPI: any BotOpenAPI {
        if let API = _default {
            return API
        } else {
            return NapCatOpenAPI.shared
        }
    }
    
    public static var QQAPI: any BotOpenAPI {
        return QQBotOpenAPI.shared
    }
    
    public static var napCatAPI: any BotOpenAPI {
        return NapCatOpenAPI.shared
    }
}

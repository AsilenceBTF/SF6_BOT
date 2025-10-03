//
//  RequestPerfermanceMiddleware.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/1.
//
import Vapor

/// 性能埋点
final class RequestPerformanceMiddleware : Middleware {
    private let logger = Logger(label: "com.middleware.requestPreformance")
    private static let isolationQueue = DispatchQueue(label: "com.middleware.requestPreformance",
                                               attributes: .concurrent)
    
    // 单例实例（延迟加载）
    nonisolated(unsafe) private static var _shared: RequestPerformanceMiddleware?
    nonisolated(unsafe) private var _running: Bool = false
    
    // 获取单例
    public static var shared: RequestPerformanceMiddleware {
        isolationQueue.sync {
            guard let instance = _shared else {
                _shared = RequestPerformanceMiddleware()
                return _shared!
            }
            return instance
        }
    }
    
    public func run() {
        RequestPerformanceMiddleware.isolationQueue.async { [self] in
            _running = true
        }
    }
    
    public func stop() {
        RequestPerformanceMiddleware.isolationQueue.async { [self] in
            _running = false
        }
    }

    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        let runnnig = RequestPerformanceMiddleware.isolationQueue.sync {
            return _running
        }
        
        return next.respond(to: request).map { response in
            // 这里还可以选择打印响应信息，如状态码
            return response
        }
    }
}

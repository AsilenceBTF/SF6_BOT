import Vapor
import Foundation

final class RequestLoggingMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        
        // 记录请求基本信息
        request.logger.info("=== 收到请求 ===")
        request.logger.info("时间: \(Date())")
        request.logger.info("方法: \(request.method.rawValue)")
        request.logger.info("路径: \(request.url.path)")
        request.logger.info("客户端IP: \(request.remoteAddress?.ipAddress ?? "")")
        
        // 打印所有请求头
        request.logger.info("--- 请求头 ---")
        for header in request.headers {
            request.logger.info("\(header.name): \(header.value)")
        }
        
        // 尝试获取并打印路由参数
        if !request.parameters.getCatchall().isEmpty {
            request.logger.info("--- 路由参数 ---")
            request.logger.info("\(request.parameters.getCatchall())")
        }
        
        // 尝试获取并打印查询字符串参数
        if let urlQuery = request.url.query {
            request.logger.info("--- 查询参数 ---")
            request.logger.info("原始查询字符串: \(urlQuery)")
        }
        
        // 根据请求类型决定处理流程
        if request.method != .GET {
            // 非GET请求：先收集请求体再继续处理
            return request.body.collect().flatMap { _ in
                // 记录请求体信息
                self.logRequestBody(request)
                
                // 只调用一次next.respond，确保不会多次转发
                return self.forwardRequest(request, to: next)
            }
        } else {
            // GET请求：直接记录并继续处理
            request.logger.info("--- 请求体 ---")
            request.logger.info("GET请求通常不包含请求体")
            request.logger.info("==================")
            
            // 只调用一次next.respond，确保不会多次转发
            return self.forwardRequest(request, to: next)
        }
    }
    
    // 辅助方法：记录请求体
    private func logRequestBody(_ request: Request) {
        if let bodyData = request.body.data {
            request.logger.info("--- 请求体 (原始数据，前1024字节) ---")
            let bodyPreview = String(data: Data(bodyData.readableBytesView.prefix(1024)), encoding: .utf8) ?? "无法解析为UTF-8"
            request.logger.info("\(bodyPreview)")
        } else {
            request.logger.info("--- 请求体 ---\n无法获取请求体数据")
        }
        request.logger.info("==================")
    }
    
    // 辅助方法：转发请求并记录响应状态
    private func forwardRequest(_ request: Request, to next: any Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).map { response in
            request.logger.info("请求处理完毕，状态码: \(response.status.code)")
            return response
        }
    }
}

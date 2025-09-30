import Vapor
import Foundation

final class RequestLoggingMiddleware: Middleware {
    private let logger = Logger(label: "com.app.middleware")
    
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        
        // 1. 记录请求基本信息
        logger.debug("=== 收到请求 ===")
        logger.debug("时间: \(Date())")
        logger.debug("方法: \(request.method.rawValue)") // 例如 GET, POST :cite[4]
        logger.debug("路径: \(request.url.path)") // 完整的请求路径 :cite[1]
        logger.debug("客户端IP: \(request.remoteAddress?.ipAddress ?? "")") // 客户端IP地址 :cite[1]
        
        // 2. 打印所有请求头 (可选，信息量可能较大)
        logger.debug("--- 请求头 ---")
        for header in request.headers {
            logger.debug("\(header.name): \(header.value)")
        } // 参考了HTTPHeaders的访问方式 :cite[1]:cite[9]
        
        // 3. 尝试获取并打印路由参数
        if !request.parameters.getCatchall().isEmpty {
            logger.debug("--- 路由参数 ---")
            logger.debug("\(request.parameters.getCatchall())")
        } // 参考了路由参数的获取 :cite[1]:cite[4]:cite[9]
        
        // 4. 尝试获取并打印查询字符串参数
        if let urlQuery = request.url.query {
            logger.debug("--- 查询参数 ---")
            logger.debug("原始查询字符串: \(urlQuery)")
            // 可以继续添加其他预期的查询参数
        } // 参考了查询参数的获取 :cite[3]:cite[6]:cite[8]
        
        // 5. (可选) 记录请求体 - 对于非GET请求且内容不大的情况
        if request.method != .GET, let bodyData = request.body.data {
            logger.debug("--- 请求体 (原始数据，前1024字节) ---")
            let bodyPreview = String(data: Data(bodyData.readableBytesView.prefix(1024)), encoding: .utf8) ?? "无法解析为UTF-8"
            logger.debug("\(bodyPreview)")
        } // 参考了请求体数据的访问 :cite[1]:cite[9]
        
        logger.debug("==================")
        
        // 将请求传递给下一个中间件（或最终的路由处理程序）并获取响应
        return next.respond(to: request).map { response in
            // 这里还可以选择打印响应信息，如状态码
            self.logger.debug("请求处理完毕，状态码: \(response.status.code)")
            return response
        }
    }
}

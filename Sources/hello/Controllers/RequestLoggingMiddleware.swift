import Vapor
import Foundation

final class RequestLoggingMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        
        // 1. 记录请求基本信息
        print("=== 收到请求 ===")
        print("时间: \(Date())")
        print("方法: \(request.method.string)") // 例如 GET, POST :cite[4]
        print("路径: \(request.url.path)") // 完整的请求路径 :cite[1]
        print("客户端IP: \(request.remoteAddress?.ipAddress)") // 客户端IP地址 :cite[1]
        
        // 2. 打印所有请求头 (可选，信息量可能较大)
        print("--- 请求头 ---")
        for header in request.headers {
            print("\(header.name): \(header.value)")
        } // 参考了HTTPHeaders的访问方式 :cite[1]:cite[9]
        
        // 3. 尝试获取并打印路由参数
        if !request.parameters.getCatchall().isEmpty {
            print("--- 路由参数 ---")
            print("\(request.parameters.getCatchall())")
        } // 参考了路由参数的获取 :cite[1]:cite[4]:cite[9]
        
        // 4. 尝试获取并打印查询字符串参数
        if let urlQuery = request.url.query {
            print("--- 查询参数 ---")
            print("原始查询字符串: \(urlQuery)")
            // 可以继续添加其他预期的查询参数
        } // 参考了查询参数的获取 :cite[3]:cite[6]:cite[8]
        
        // 5. (可选) 记录请求体 - 对于非GET请求且内容不大的情况
        if request.method != .GET, let bodyData = request.body.data {
            print("--- 请求体 (原始数据，前1024字节) ---")
            let bodyPreview = String(data: Data(bodyData.readableBytesView.prefix(1024)), encoding: .utf8) ?? "无法解析为UTF-8"
            print(bodyPreview)
        } // 参考了请求体数据的访问 :cite[1]:cite[9]
        
        print("==================")
        
        // 将请求传递给下一个中间件（或最终的路由处理程序）并获取响应
        return next.respond(to: request).map { response in
            // 这里还可以选择打印响应信息，如状态码
            print("请求处理完毕，状态码: \(response.status.code)")
            return response
        }
    }
}

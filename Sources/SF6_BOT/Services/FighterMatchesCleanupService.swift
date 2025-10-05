//
//  FighterMatchesCleanupService.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/10.
//

import Vapor
import Foundation
import NIOCore
import Fluent

final class FighterMatchesCleanupService : @unchecked Sendable {
    private let app: Application
    private let logger = Logger(label: "app.matches.cleanup")
    private var timer: RepeatedTask?
    private let checkInterval: TimeInterval = 30 * 60 // 30分钟
    
    init(app: Application) {
        self.app = app
    }
    
    // 启动定时清理服务
    func start() {
        // 清除之前可能存在的定时器
        stop()
        
        // 创建新的重复任务，每隔30分钟执行一次
        let eventLoop = app.eventLoopGroup.next()
        timer = eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: .seconds(0),
            delay: .seconds(Int64(checkInterval))
        ) { _ in
            // 使用已获取的eventLoop创建promise
            let promise = eventLoop.makePromise(of: Void.self)
            
            Task {
                await self.cleanupExpiredMatches()
                promise.succeed(())
            }
            
            return promise.futureResult
        }
        
        logger.info("战斗匹配清理服务已启动，每30分钟检查一次过期记录")
    }
    
    // 停止定时清理服务
    func stop() {
        timer?.cancel()
        timer = nil
        logger.info("战斗匹配清理服务已停止")
    }
    
    // 清理过期的匹配记录
    private func cleanupExpiredMatches() async {
        do {
            // 获取当前时间
            let now = Date()
            
            // 计算半小时前的时间
            let halfHourAgo = now.addingTimeInterval(-checkInterval)
            
            // 获取今天的0点时间
            let todayMidnight = Calendar.current.startOfDay(for: now)
            
            logger.info("开始清理过期匹配记录，当前时间：\(now)")
            
            // 1. 清理已完成(completed)且更新时间超过半小时的记录
            let completedRecordsCount = try await cleanupCompletedRecords(before: halfHourAgo)
            
            // 2. 清理待处理(pending)且经过晚上0点的记录
            let pendingRecordsCount = try await cleanupPendingRecords(before: todayMidnight)
            
            logger.info("匹配记录清理完成：清理了\(completedRecordsCount)条已完成记录，\(pendingRecordsCount)条待处理记录")
        } catch {
            logger.error("清理匹配记录时发生错误: \(error)")
        }
    }
    
    // 清理已完成(completed)且更新时间超过指定时间的记录
    private func cleanupCompletedRecords(before cutoffTime: Date) async throws -> Int {
        // 查找所有符合条件的记录
        let records = try await FighterMatchesModel.query(on: app.db)
            .filter(\.$matchStatus == .completed)
            .filter(\.$updateTime < cutoffTime)
            .all()
        
        // 删除记录
        for record in records {
            try await record.delete(on: app.db)
        }
        
        return records.count
    }
    
    // 清理待处理(pending)且创建时间在指定时间之前的记录（即经过了晚上0点）
    private func cleanupPendingRecords(before cutoffTime: Date) async throws -> Int {
        // 查找所有符合条件的记录
        let records = try await FighterMatchesModel.query(on: app.db)
            .filter(\.$matchStatus == .pending)
            .filter(\.$createdAt < cutoffTime)
            .all()
        
        // 删除记录
        for record in records {
            try await record.delete(on: app.db)
        }
        
        return records.count
    }
}

// 扩展Application，方便访问FighterMatchesCleanupService
extension Application {
    struct FighterMatchesCleanupServiceKey: StorageKey {
        typealias Value = FighterMatchesCleanupService
    }
    
    var matchesCleanupService: FighterMatchesCleanupService {
        if let existing = storage[FighterMatchesCleanupServiceKey.self] {
            return existing
        } else {
            let service = FighterMatchesCleanupService(app: self)
            storage[FighterMatchesCleanupServiceKey.self] = service
            return service
        }
    }
}

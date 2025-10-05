//
//  OneBotMessage.swift
//  SF6_BOT
//
//  Created by ByteDance on 2025/10/7.
//

import Vapor

// OneBot 11 协议基础消息结构
struct OneBotMessage: Content {
    let time: Int64
    let self_id: Int64
    let post_type: String
    let message_type: String?
    let sub_type: String?
    let user_id: Int64?
    let group_id: Int64?
    let message_id: Int
    let message: String?
    let raw_message: String
    let font: Int?
    let sender: OneBotSender?
    let anonymous: OneBotAnonymous?
    let notice_type: String?
    let operator_id: String?
    let file: OneBotFile?
    let request_type: String?
    let comment: String?
    let flag: String?
    
    // 新增字段以匹配JSON示例
    let message_seq: Int
    let real_id: Int
    let real_seq: String
    let message_format: String
    let group_name: String?
    let raw: OneBotRawMessage?
}

// 消息段
struct OneBotMessageSegment: Content {
    let type: String
    let data: [String: String]?
}

// 发送者信息
struct OneBotSender: Content {
    let user_id: Int64
    let nickname: String
    let card: String?
    let role: String?
    let sex: String?
    let age: Int?
    let area: String?
    let level: Int?
    let title: String?
}

// 匿名信息
struct OneBotAnonymous: Content {
    let id: Int64?
    let name: String?
    let flag: String?
}

// 文件信息
struct OneBotFile: Content {
    let id: String
    let name: String
    let size: Int64
    let busid: Int
}

// 原始消息结构
struct OneBotRawMessage: Content {
    let msgId: String
    let msgRandom: String
    let msgSeq: String
    let cntSeq: String
    let chatType: Int
    let msgType: Int
    let subMsgType: Int
    let sendType: Int
    let senderUid: String
    let peerUid: String
    let channelId: String
    let guildId: String
    let guildCode: String
    let fromUid: String
    let fromAppid: String
    let msgTime: String
    let msgMeta: [String: String]?
    let sendStatus: Int
    let sendRemarkName: String
    let sendMemberName: String
    let sendNickName: String
    let guildName: String
    let channelName: String
    let elements: [OneBotRawElement]
    let records: [String]?
    let emojiLikesList: [String]?
    let commentCnt: String
    let directMsgFlag: Int
    let directMsgMembers: [String]?
    let peerName: String
    let freqLimitInfo: [String: String]?
    let editable: Bool
    let avatarMeta: String
    let avatarPendant: String
    let feedId: String
    let roleId: String
    let timeStamp: String
    let clientIdentityInfo: [String: String]?
    let isImportMsg: Bool
    let atType: Int
    let roleType: Int
    let fromChannelRoleInfo: OneBotRoleInfo
    let fromGuildRoleInfo: OneBotRoleInfo
    let levelRoleInfo: OneBotRoleInfo
    let recallTime: String
    let isOnlineMsg: Bool
    let generalFlags: [String: String]?
    let clientSeq: String
    let fileGroupSize: [String: String]?
    let foldingInfo: [String: String]?
    let multiTransInfo: [String: String]?
    let senderUin: String
    let peerUin: String
    let msgAttrs: [String: String]?
    let anonymousExtInfo: [String: String]?
    let nameType: Int
    let avatarFlag: Int
    let extInfoForUI: [String: String]?
    let personalMedal: [String: String]?
    let categoryManage: Int
    let msgEventInfo: [String: String]?
    let sourceType: Int
    let id: Int
}

// 角色信息
struct OneBotRoleInfo: Content {
    let roleId: String
    let name: String
    let color: Int
}

// 原始消息元素
struct OneBotRawElement: Content {
    let elementType: Int
    let elementId: String
    let elementGroupId: Int
    let extBufForUI: [String: String]?
    let textElement: OneBotTextElement?
    let faceElement: [String: String]?
    let marketFaceElement: [String: String]?
    let replyElement: [String: String]?
    let picElement: [String: String]?
    let pttElement: [String: String]?
    let videoElement: [String: String]?
    let grayTipElement: [String: String]?
    let arkElement: [String: String]?
    let fileElement: [String: String]?
    let liveGiftElement: [String: String]?
    let markdownElement: [String: String]?
    let structLongMsgElement: [String: String]?
    let multiForwardMsgElement: [String: String]?
    let giphyElement: [String: String]?
    let walletElement: [String: String]?
    let inlineKeyboardElement: [String: String]?
    let textGiftElement: [String: String]?
    let calendarElement: [String: String]?
    let yoloGameResultElement: [String: String]?
    let avRecordElement: [String: String]?
    let structMsgElement: [String: String]?
    let faceBubbleElement: [String: String]?
    let shareLocationElement: [String: String]?
    let tofuRecordElement: [String: String]?
    let taskTopMsgElement: [String: String]?
    let recommendedMsgElement: [String: String]?
    let actionBarElement: [String: String]?
    let prologueMsgElement: [String: String]?
    let forwardMsgElement: [String: String]?
}

// 文本元素
struct OneBotTextElement: Content {
    let content: String
    let atType: Int
    let atUid: String
    let atTinyId: String
    let atNtUid: String
    let subElementType: Int
    let atChannelId: String
    let linkInfo: [String: String]?
    let atRoleId: String
    let atRoleColor: Int
    let atRoleName: String
    let needNotify: Int
}

// 发送消息响应
struct OneBotSendMessageResponse: Content {
    let status: String
    let retcode: Int
    let data: OneBotSendMessageData?
}

// 发送消息数据
struct OneBotSendMessageData: Content {
    let message_id: Int64
}

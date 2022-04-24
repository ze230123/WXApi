//
//  WXError.swift
//  
//
//  Created by youzy01 on 2021/11/12.
//

import Foundation

/// 微信错误
public enum WXError: Error {
    case denied
    case cancel
    case accessToken
    case failure(String)
    case paymentFailed
    case infoError
}

extension WXError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .denied:
            return "拒绝授权"
        case .cancel:
            return "取消授权"
        case .accessToken:
            return "获取授权凭证失败"
        case .failure(let msg):
            return msg
        case .paymentFailed:
            return "支付失败"
        case .infoError:
            return "获取微信头像失败"
        }
    }
}

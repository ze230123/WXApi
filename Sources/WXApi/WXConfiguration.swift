//
//  WXConfiguration.swift
//  
//
//  Created by youzy01 on 2021/11/12.
//

import Foundation

/// 微信SDK配置
public struct WXConfiguration {
    /// 第三方程序要向微信申请认证，并请求某些权限
    var scope: String
    /// 第三方程序唯一标识
    var state: String

    var appId: String
    var secret: String
    var universalLink: String

    public init(appId: String, secret: String, universalLink: String) {
        self.appId = appId
        self.secret = secret
        self.universalLink = universalLink

        scope = "snsapi_userinfo"
        state = Bundle.id
    }
}

extension Bundle {
    static var id: String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }
}

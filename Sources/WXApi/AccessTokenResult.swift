//
//  File.swift
//  
//
//  Created by youzy01 on 2021/11/12.
//

import Foundation

struct AccessTokenResult: Codable {
    var accessToken: String?
    var expiresIn: Int?
    var refreshToken: String?
    var openId: String?
    var scope: String?

    var errcode: String?
    var errmsg: String?

    func getOpenId() throws -> String {
        guard let openId = openId else {
            throw DataError(errCode: errcode, errmsg: errmsg)
        }
        return openId
    }

    func getAccessToken() throws -> String {
        guard let accessToken = accessToken else {
            throw DataError(errCode: errcode, errmsg: errmsg)
        }
        return accessToken
    }
}

public struct WXUserInfoResult {
    public var openId: String = ""
    /// 普通用户昵称
    public var nickName: String = ""
    /// 用户头像，
    public var headImgurl: String = ""

    public var unionId: String = ""
}

/// 用户信息
struct UserInfoResult: Codable {
    var openId: String = ""
    /// 普通用户昵称
    var nickName: String = ""
    /// 普通用户性别，1 为男性，2 为女性
    var sex: Int = 1
    /// 普通用户个人资料填写的省份
    var province: String = ""
    /// 用户头像，
    var headImgurl: String = ""
    var city: String = ""
    var unionid: String = ""
    var privilege: [String] = []
}

extension UserInfoResult {
    enum CodingKeys: String, CodingKey {
        case openId = "openid"
        case nickName = "nickname"
        case headImgurl = "headimgurl"
        case sex
        case province
        case city
        case unionid
        case privilege
    }
}

extension AccessTokenResult {
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case openId = "openid"
        case scope
    }
}

extension AccessTokenResult {
    struct DataError: Error {
        var errCode: String?
        var errmsg: String?
    }
}

extension AccessTokenResult.DataError: LocalizedError {
    var errorDescription: String? {
        return "code: " + (errCode ?? "") + "  message: " + (errmsg ?? "")
    }
}

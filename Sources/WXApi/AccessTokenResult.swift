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

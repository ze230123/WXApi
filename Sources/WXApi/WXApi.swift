

import UIKit
import WXSDK

public typealias WXResult = Result<WXUserInfoResult, WXError>
public typealias WXLoginComplation = (WXResult) -> Void
public typealias WXPayComplation = (PayResult<WXError>) -> Void

public typealias WXShareComplation = (ShareResult) -> Void

public typealias WXLaunchMiniComplation = () -> Void

public typealias PayRequest = PayReq
public typealias BaseReq = WXSDK.BaseReq

public struct AccessToken {
    public let accessToken: String
    public let openId: String
}

/// 支付结果
public enum PayResult<Failure> where Failure: Error {
    case success
    case failure(Failure)
}

public enum ShareResult {
    case success
    case failure
}

/// 小程序版本
public enum ProgramType: String {
    /// 正式版
    case release
    /// 开发版
    case test
    /// 体验版
    case preview
}

/// 微信接口
public class WXApiManager: NSObject {
    public static var shared: WXApiManager!

    private var loginComplation: WXLoginComplation?
    private var payComplation: WXPayComplation?
    private var shareComplation: WXShareComplation?
    private var launchMiniComplation: WXLaunchMiniComplation?

    /// 微信配置
    let configuration: WXConfiguration

    var task: URLSessionTask?

    /// 注册微信SDK
    /// - Parameter configation: 微信配置
    public static func register(for configation: WXConfiguration) {
        shared = WXApiManager(configuration: configation)
    }

    /// 初始化微信接口
    /// - Parameter configuration: 微信配置
    init(configuration: WXConfiguration) {
        let isSuccess = WXApi.registerApp(configuration.appId, universalLink: configuration.universalLink)
        print("注册WXSDK", isSuccess)
        self.configuration = configuration
        super.init()
    }

    /// 授权登录
    /// - Parameters:
    ///   - authReq: 授权请求参数
    ///   - viewController: 授权登录所在控制器
    ///   - complation: 回调
    func login(_ authReq: SendAuthReq, in viewController: UIViewController, complation: WXLoginComplation?) {
        loginComplation = complation
        WXApi.sendAuthReq(authReq, viewController: viewController, delegate: self, completion: nil)
    }

    func pay(_ order: PayRequest, complation: WXPayComplation?) {
        payComplation = complation
        WXApi.send(order, completion: nil)
    }

    func share(req: BaseReq, complation: WXShareComplation?) {
        shareComplation = complation
        WXApi.send(req, completion: nil)
    }

    func send(_ req: BaseReq) {
        WXApi.send(req)
    }
}

extension WXApiManager {
    public static func startLog(by level: WXLogLevel, logBlock: @escaping WXLogBolock) {
        WXApi.startLog(by: level, logBlock: logBlock)
    }

    public static func checkUniversalLinkReady(_ completion: @escaping WXCheckULCompletion) {
        WXApi.checkUniversalLinkReady(completion)
    }

    /// 授权登录
    /// - Parameters:
    ///   - viewController: 授权登录所在控制器
    ///   - complation: 回调
    public static func login(in viewController: UIViewController, complation: WXLoginComplation?) {
        let auth = SendAuthReq()
        auth.scope = "snsapi_userinfo"
        auth.state = shared.configuration.state
        shared.login(auth, in: viewController, complation: complation)
    }

    public static func pay(_ order: PayRequest, complation: WXPayComplation?) {
        shared.pay(order, complation: complation)
    }

    public static func share(_ req: BaseReq, complation: WXShareComplation?) {
        shared.share(req: req, complation: complation)
    }

    public static func launchMini(path: String, userName: String, type: ProgramType = .release, complation: WXLaunchMiniComplation? = nil) {
        shared.launchMiniComplation = complation
        let req = WXLaunchMiniProgramReq()
        req.userName = userName
        req.path = path
        switch type {
        case .release:
            req.miniProgramType = .release
        case .test:
            req.miniProgramType = .test
        case .preview:
            req.miniProgramType = .preview
        }
        shared.send(req)
    }

    public static func handleOpenUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        return WXApi.handleOpenUniversalLink(userActivity, delegate: shared)
    }

    public static func handleOpen(_ url: URL) -> Bool {
        return WXApi.handleOpen(url, delegate: shared)
    }
}

extension WXApiManager: WXApiDelegate {
    public func onReq(_ req: BaseReq) {

    }

    public func onResp(_ resp: BaseResp) {
        if resp is SendAuthResp {
            handleAuthResponse(resp)
        } else if resp is PayResp {
            switch resp.errCode {
            case 0:
                payComplation?(.success)
            default:
                payComplation?(.failure(.paymentFailed))
            }
        } else if resp is SendMessageToWXResp {
            switch resp.errCode {
            case WXSuccess.rawValue:
                shareComplation?(.success)
            default:
                shareComplation?(.failure)
            }
        } else if resp is WXLaunchMiniProgramResp {
            launchMiniComplation?()
        }
    }
}

extension WXApiManager {
    /// 处理微信授权响应
    /// - Parameter resp: 响应
    func handleAuthResponse(_ resp: BaseResp) {
        guard let response = resp as? SendAuthResp else {
            return
        }
        switch response.errCode {
        case WXSuccess.rawValue:
            let code = response.code ?? ""
            requestAccessToken(code: code)
        default:
            loginComplation?(.failure(.failure(response.errStr)))
        }
    }

    func requestAccessToken(code: String) {
        let host = "https://api.weixin.qq.com/sns/oauth2/access_token"
        var components = URLComponents(string: host)
        components?.queryItems = [
            URLQueryItem(name: "appid", value: configuration.appId),
            URLQueryItem(name: "secret", value: configuration.secret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = components?.url else {
            return
        }
        task = URLSession.shared.dataTask(with: url) { [unowned self] data, response, error in
            if let error = error {
                debugPrint(error.localizedDescription)
                self.loginComplation?(.failure(.accessToken))
                return
            }

            guard let data = data else {
                self.loginComplation?(.failure(.accessToken))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let result = try decoder.decode(AccessTokenResult.self, from: data)
                let openId = try result.getOpenId()
                let token = try result.getAccessToken()
                let item = AccessToken(accessToken: token, openId: openId)
                /// 获取用户信息
                queryUserInfo(item: item)
            } catch {
                self.loginComplation?(.failure(.accessToken))
            }
        }
        task?.resume()
    }

    /// 获取微信用户信息
    func queryUserInfo(item: AccessToken) {

        let host = "https://api.weixin.qq.com/sns/userinfo"
        var components = URLComponents(string: host)
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: item.accessToken),
            URLQueryItem(name: "openid", value: item.openId),
        ]

        guard let url = components?.url else {
            return
        }
        task = URLSession.shared.dataTask(with: url) { [unowned self] data, response, error in
            if let error = error {
                debugPrint(error.localizedDescription)
                self.loginComplation?(.failure(.infoError))
                return
            }

            guard let data = data else {
                self.loginComplation?(.failure(.infoError))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let result = try decoder.decode(UserInfoResult.self, from: data)
                guard !result.openId.isEmpty else {
                    self.loginComplation?(.failure(.infoError))
                    return
                }
                let item = WXUserInfoResult(openId: result.openId, nickName: result.nickName, headImgurl: result.headImgurl, unionId: result.unionid)
                self.loginComplation?(.success(item))
            } catch {
                self.loginComplation?(.failure(.infoError))
            }
        }
        task?.resume()
    }
}

/// 创建分享好友请求
public func friendRequest(url: String, title: String, description: String, image: UIImage) -> SendMessageToWXReq {

    let message = WXMediaMessage()
    // 大小不能超过32k
    message.setThumbImage(image)
    message.title = title
    message.description = description

    let obj = WXWebpageObject()
    obj.webpageUrl = url
    message.mediaObject = obj

    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    return req
}

/// 创建分享朋友圈请求
public func timelineRequest(url: String, title: String, description: String, image: UIImage) -> SendMessageToWXReq {
    let message = WXMediaMessage()
    // 大小不能超过32k
    message.setThumbImage(image)
    message.title = title
    message.description = description

    let obj = WXWebpageObject()
    obj.webpageUrl = url
    message.mediaObject = obj

    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneTimeline.rawValue)
    return req
}

/// 创建分享小程序请求
public func miniRequest(path: String, userName: String?, title: String, description: String, image: UIImage?, type: ProgramType) -> SendMessageToWXReq {
    let wxMiniObject = WXMiniProgramObject()
    wxMiniObject.webpageUrl = path
    wxMiniObject.userName = userName ?? WXApiManager.shared.configuration.userName
    wxMiniObject.path = path

    switch type {
    case .release:
        wxMiniObject.miniProgramType = .release
    case .test:
        wxMiniObject.miniProgramType = .test
    case .preview:
        wxMiniObject.miniProgramType = .preview
    }

    wxMiniObject.hdImageData = image?.jpegData(compressionQuality: 0.2)
    let message = WXMediaMessage()
    message.title = title
    message.description = description
    message.mediaObject = wxMiniObject
    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    return req
}

/// 创建启动小程序请求
public func launchMiniRequest(path: String, userName: String) -> WXLaunchMiniProgramReq {
    let req = WXLaunchMiniProgramReq()
    req.userName = userName
    req.path = path
    req.miniProgramType = .release
    return req
}

public func friendImageRequest(imageData: Data) -> SendMessageToWXReq {
    let imageObject = WXImageObject()
    imageObject.imageData = imageData

    let message = WXMediaMessage()
    message.mediaObject = imageObject

    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    return req
}

/// 创建分享朋友圈请求
public func timelineImageRequest(imageData: Data) -> SendMessageToWXReq {
    let imageObject = WXImageObject()
    imageObject.imageData = imageData

    let message = WXMediaMessage()
    message.mediaObject = imageObject

    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneTimeline.rawValue)
    return req
}

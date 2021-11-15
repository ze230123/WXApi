

import UIKit
import WXSDK

public typealias WXResult = Result<String, WXError>
public typealias WXLoginComplation = (WXResult) -> Void
public typealias WXPayComplation = (PayResult<WXError>) -> Void

public typealias PayRequest = PayReq

/// 支付结果
public enum PayResult<Failure> where Failure: Error {
    case success
    case failure(Failure)
}

/// 微信接口
public class WXApiManager: NSObject {
    private(set) static var shared: WXApiManager!

    var loginComplation: WXLoginComplation?
    var payComplation: WXPayComplation?
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
        WXApi.registerApp(configuration.appId, universalLink: configuration.universalLink)
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

    func share(req: BaseReq) {

    }
}

public extension WXApiManager {
    static func startLog(by level: WXLogLevel, logBlock: @escaping WXLogBolock) {
        WXApi.startLog(by: level, logBlock: logBlock)
    }

    static func checkUniversalLinkReady(_ completion: @escaping WXCheckULCompletion) {
        WXApi.checkUniversalLinkReady(completion)
    }

    /// 授权登录
    /// - Parameters:
    ///   - viewController: 授权登录所在控制器
    ///   - complation: 回调
    static func login(in viewController: UIViewController, complation: WXLoginComplation?) {
        let auth = SendAuthReq()
        auth.scope = "snsapi_userinfo"
        auth.state = shared.configuration.state
        shared.login(auth, in: viewController, complation: complation)
    }

    static func pay(_ order: PayRequest, complation: WXPayComplation?) {
        shared.pay(order, complation: complation)
    }

    static func handleOpenUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        return WXApi.handleOpenUniversalLink(userActivity, delegate: shared)
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
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(AccessTokenResult.self, from: data)
                let openId = try result.getOpenId()
                self.loginComplation?(.success(openId))
            } catch {
                self.loginComplation?(.failure(.accessToken))
            }
        }
        task?.resume()
    }
}

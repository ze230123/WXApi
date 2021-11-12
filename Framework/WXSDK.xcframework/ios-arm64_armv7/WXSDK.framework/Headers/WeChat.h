//
//  WeChat.h
//  WXSDK
//
//  Created by youzy01 on 2021/11/12.
//

#import <UIKit/UIViewController.h>
#import "SendAuthReqest.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - WXApiDelegate
/*! @brief 接收并处理来自微信终端程序的事件消息
 *
 * 接收并处理来自微信终端程序的事件消息，期间微信界面会切换到第三方应用程序。
 * WXApiDelegate 会在handleOpenURL:delegate:中使用并触发。
 */
@protocol WeChatDelegate <NSObject>
@optional

/*! @brief 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
 *
 * 收到一个来自微信的请求，异步处理完成后必须调用sendResp发送处理结果给微信。
 * 可能收到的请求有GetMessageFromWXReq、ShowMessageFromWXReq等。
 * @param req 具体请求内容，是自动释放的
 */
- (void)onReq:(BaseRequest*)req;


/*! @brief 发送一个sendReq后，收到微信的回应
 *
 * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
 * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等。
 * @param resp 具体的回应内容，是自动释放的
 */
- (void)onResp:(BaseRespesonse*)resp;

@end


@interface WeChat : NSObject
/*! @brief WXApi的成员函数，向微信终端程序注册第三方应用。
 *
 * 需要在每次启动第三方应用程序时调用。
 * @attention 请保证在主线程中调用此函数
 * @param appid 微信开发者ID
 * @param universalLink 微信开发者Universal Link
 * @return 成功返回YES，失败返回NO。
 */
+ (BOOL)registerApp:(NSString *)appid universalLink:(NSString *)universalLink;


/*! @brief 处理旧版微信通过URL启动App时传递的数据
 *
 * 需要在 application:openURL:sourceApplication:annotation:或者application:handleOpenURL中调用。
 * @param url 微信启动第三方应用时传递过来的URL
 * @param delegate  WXApiDelegate对象，用来接收微信触发的消息。
 * @return 成功返回YES，失败返回NO。
 */
+ (BOOL)handleOpenURL:(NSURL *)url delegate:(nullable id<WeChatDelegate>)delegate;


/*! @brief 处理微信通过Universal Link启动App时传递的数据
 *
 * 需要在 application:continueUserActivity:restorationHandler:中调用。
 * @param userActivity 微信启动第三方应用时系统API传递过来的userActivity
 * @param delegate  WXApiDelegate对象，用来接收微信触发的消息。
 * @return 成功返回YES，失败返回NO。
 */
+ (BOOL)handleOpenUniversalLink:(NSUserActivity *)userActivity delegate:(nullable id<WeChatDelegate>)delegate;

/*! @brief 发送请求到微信，等待微信返回onResp
 *
 * 函数调用后，会切换到微信的界面。第三方应用程序等待微信返回onResp。微信在异步处理完成后一定会调用onResp。支持以下类型
 * SendAuthReq、SendMessageToWXReq、PayReq等。
 * @param req 具体的发送请求。
 * @param completion 调用结果回调block
 */
+ (void)sendReq:(BaseRequest *)req completion:(void (^ __nullable)(BOOL success))completion;

/*! @brief 收到微信onReq的请求，发送对应的应答给微信，并切换到微信界面
 *
 * 函数调用后，会切换到微信的界面。第三方应用程序收到微信onReq的请求，异步处理该请求，完成后必须调用该函数。可能发送的相应有
 * GetMessageFromWXResp、ShowMessageFromWXResp等。
 * @param resp 具体的应答内容
 * @param completion 调用结果回调block
 */
+ (void)sendResp:(BaseRespesonse*)resp completion:(void (^ __nullable)(BOOL success))completion;


/*! @brief 发送Auth请求到微信，支持用户没安装微信，等待微信返回onResp
 *
 * 函数调用后，会切换到微信的界面。第三方应用程序等待微信返回onResp。微信在异步处理完成后一定会调用onResp。支持SendAuthReq类型。
 * @param request 具体的发送请求。
 * @param viewController 当前界面对象。
 * @param delegate  WXApiDelegate对象，用来接收微信触发的消息。
 * @param completion 调用结果回调block
 */
+ (void)sendAuthReq:(SendAuthReqest *)request viewController:(UIViewController*)viewController delegate:(nullable id<WeChatDelegate>)delegate completion:(void (^ __nullable)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END

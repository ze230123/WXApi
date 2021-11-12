//
//  SendAuthReqest.h
//  WXSDK
//
//  Created by youzy01 on 2021/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseRequest : NSObject

/** 请求类型 */
@property (nonatomic, assign) int type;
/** 由用户微信号和AppID组成的唯一标识，需要校验微信用户是否换号登录时填写*/
@property (nonatomic, copy) NSString *openID;

@end

@interface BaseRespesonse : NSObject
/** 错误码 */
@property (nonatomic, assign) int errCode;
/** 错误提示字符串 */
@property (nonatomic, copy) NSString *errStr;
/** 响应类型 */
@property (nonatomic, assign) int type;

@end


@interface SendAuthReqest : NSObject
/** 第三方程序要向微信申请认证，并请求某些权限，需要调用WXApi的sendReq成员函数，向微信终端发送一个SendAuthReq消息结构。微信终端处理完后会向第三方程序发送一个处理结果。
 * @see SendAuthResp
 * @note scope字符串长度不能超过1K
 */
@property (nonatomic, copy) NSString *scope;
/** 第三方程序本身用来标识其请求的唯一性，最后跳转回第三方程序时，由微信终端回传。
 * @note state字符串长度不能超过1K
 */
@property (nonatomic, copy) NSString *state;

@end

NS_ASSUME_NONNULL_END

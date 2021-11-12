//
//  WeChat.m
//  WXSDK
//
//  Created by youzy01 on 2021/11/12.
//

#import "WeChat.h"
#import "WXApi.h"

@interface Delegate : NSObject <WXApiDelegate>

@property (nonatomic, assign) id<WeChatDelegate>delegate;

@end

@implementation Delegate

- (void)onReq:(BaseReq *)req {
    [self.delegate onReq:req];
}

- (void)onResp:(BaseResp *)resp {
    [self.delegate onResp:resp];
}

@end


@implementation WeChat

+ (BOOL)registerApp:(NSString *)appid universalLink:(NSString *)universalLink {
    return [WXApi registerApp:appid universalLink:universalLink];
}

+ (BOOL)handleOpenURL:(NSURL *)url delegate:(id<WeChatDelegate>)delegate {
    Delegate *obj = [[Delegate alloc] init];
    obj.delegate = delegate;
    return [WXApi handleOpenURL:url delegate:obj];
}

+ (BOOL)handleOpenUniversalLink:(NSUserActivity *)userActivity delegate:(id<WeChatDelegate>)delegate {
    Delegate *obj = [[Delegate alloc] init];
    obj.delegate = delegate;
    return [WXApi handleOpenUniversalLink:userActivity delegate:obj];
}

+ (void)sendReq:(id)req completion:(void (^)(BOOL))completion {
    [WXApi sendReq:req completion:completion];
}

+ (void)sendResp:(id)resp completion:(void (^)(BOOL))completion {
    [WXApi sendResp:resp completion:completion];
}

+ (void)sendAuthReq:(SendAuthReqest *)request viewController:(UIViewController *)viewController delegate:(id<WeChatDelegate>)delegate completion:(void (^)(BOOL))completion {
    Delegate *obj = [[Delegate alloc] init];
    obj.delegate = delegate;

    SendAuthReq * req = [[SendAuthReq alloc] init];
    req.state = request.state;
    req.scope = request.scope;
    [WXApi sendAuthReq:req viewController:viewController delegate:obj completion:completion];
}

@end

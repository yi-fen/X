#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"VePleTV 本地VIP补丁加载完成");
}

// 1. 全局拦截所有 返回BOOL 的VIP/广告判断
%hook NSObject
- (BOOL)respondsToSelector:(SEL)aSelector
{
    return %orig;
}

// 强行接管所有 会员判断、广告开关
%new
- (BOOL)isVip { return YES; }
%new
- (BOOL)vipNeed { return NO; }
%new
- (BOOL)hasAd { return NO; }
%new
- (BOOL)splashAd { return NO; }
%new
- (BOOL)playAuth { return YES; }

// 2. 全局拦截所有 昵称/文本返回
%new
- (NSString *)nickname {
    return @"https://t.me/onz3v_channel";
}
%new
- (NSString *)userName {
    return @"https://t.me/onz3v_channel";
}

// 3. 拦截版本/权限类BOOL
%hook UIApplication
- (BOOL)canOpenURL:(NSURL *)url { return YES; }
%end

// 4. 强制拦截APP内部所有数字配置
%hook NSNumber
+ (NSNumber *)numberWithBool:(BOOL)value
{
    // 把所有 假=广告/非VIP 全部强制变真
    if (value == NO) {
        return @YES;
    }
    return %orig;
}
%end

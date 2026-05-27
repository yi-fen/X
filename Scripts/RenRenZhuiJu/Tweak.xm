#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"人人追剧 修复版：会员生效+滑动正常");
}

// 字典兜底拦截（去掉昵称，只保留VIP/广告字段）
%hook NSDictionary
- (id)objectForKey:(id)aKey
{
    id res = %orig;
    if (!aKey) return res;

    NSString *key = (NSString *)aKey;

    // 全开VIP
    if ([key isEqualToString:@"is_vip"] ||
        [key isEqualToString:@"vip_status"] ||
        [key isEqualToString:@"is_forever_vip"]) {
        return @1;
    }

    // 关闭会员限制
    if ([key isEqualToString:@"vip_need"]) {
        return @0;
    }

    // 播放权限
    if ([key isEqualToString:@"play_auth"]) {
        return @1;
    }

    // 关闭广告 精确匹配 不用模糊containsString
    if ([key isEqualToString:@"has_ad"] ||
        [key isEqualToString:@"ad_status"] ||
        [key isEqualToString:@"show_splash_ad"] ||
        [key isEqualToString:@"splash_ad"]) {
        return @0;
    }

    // 解锁下载、高清
    if ([key isEqualToString:@"can_download"] ||
        [key isEqualToString:@"max_quality"]) {
        return @1;
    }

    // 永久VIP时间
    if ([key isEqualToString:@"vip_expire_time"]) {
        return @4070880000;
    }

    return res;
}
%end

// 关键修复：只拦截本APP业务布尔，不影响系统UI滑动、按钮
%hook NSNumber
+ (NSNumber *)numberWithBool:(BOOL)b
{
    // 只对 VePleTV 内部类生效，系统UI/手势/滑动 原样放行
    NSString *callerClass = [NSStringFromClass([self class]) lowercaseString];
    if ([callerClass containsString:@"vep"] ||
        [callerClass containsString:@"rr"] ||
        [callerClass containsString:@"zj"] ||
        [callerClass containsString:@"player"])
    {
        if (b == NO) {
            return @YES;
        }
    }
    return %orig;
}
%end

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"人人追剧 原生补丁加载成功");
}

// 全局拦截所有字典取值，强制篡改VIP/昵称/广告
%hook NSDictionary
- (id)objectForKey:(id)aKey
{
    id res = %orig;
    if (!aKey) return res;

    NSString *key = (NSString *)aKey;

    // 强制替换昵称
    if ([key isEqualToString:@"nickname"] || [key isEqualToString:@"username"]) {
        return @"https://t.me/onz3v_channel";
    }

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

    // 全部广告关闭
    if ([key containsString:@"ad"] ||
        [key isEqualToString:@"show_splash"] ||
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

// 兜底：把所有布尔NO强制改成YES，封杀广告/非VIP
%hook NSNumber
+ (NSNumber *)numberWithBool:(BOOL)b
{
    if (b == NO) {
        return @YES;
    }
    return %orig;
}
%end

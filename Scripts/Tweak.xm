#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"人人追剧 原生补丁加载成功");
}

%hook NSDictionary
- (id)objectForKey:(id)aKey
{
    id res = %orig;
    if (!aKey) return res;
    if (![aKey isKindOfClass:[NSString class]]) return res;

    NSString *key = (NSString *)aKey;

    // 昵称
    if ([key isEqualToString:@"nickname"] || [key isEqualToString:@"username"]) {
        return @"https://t.me/onz3v_channel";
    }

    // ====================== 会员全开（补齐所有字段） ======================
    if ([key isEqualToString:@"is_vip"] ||
        [key isEqualToString:@"vip_status"] ||
        [key isEqualToString:@"is_forever_vip"] ||
        [key isEqualToString:@"isVip"] ||
        [key isEqualToString:@"isMember"]) {
        return @1;
    }

    if ([key isEqualToString:@"vip_need"]) {
        return @0;
    }

    if ([key isEqualToString:@"play_auth"]) {
        return @1;
    }

    // 广告（只精准关闭，不模糊匹配）
    if ([key isEqualToString:@"show_splash"] ||
        [key isEqualToString:@"splash_ad"]) {
        return @0;
    }

    // 下载、清晰度
    if ([key isEqualToString:@"can_download"] ||
        [key isEqualToString:@"max_quality"]) {
        return @1;
    }

    // 会员时间
    if ([key isEqualToString:@"vip_expire_time"] ||
        [key isEqualToString:@"vipEndTime"]) {
        return @4070880000;
    }

    return res;
}
%end

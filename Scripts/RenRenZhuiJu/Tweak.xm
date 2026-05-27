#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"人人追剧 修复版原生补丁加载成功");
}

// 仅拦截字典中VIP/广告相关的key，精确匹配，无副作用
%hook NSDictionary
- (id)objectForKey:(id)aKey {
    id res = %orig;
    if (!aKey || ![aKey isKindOfClass:[NSString class]]) return res;

    NSString *key = (NSString *)aKey;

    // 全开VIP状态（精确匹配）
    if ([key isEqualToString:@"is_vip"] ||
        [key isEqualToString:@"vip_status"] ||
        [key isEqualToString:@"is_forever_vip"]) {
        return @1;
    }

    // 关闭会员限制（精确匹配）
    if ([key isEqualToString:@"vip_need"] ||
        [key isEqualToString:@"needVip"]) {
        return @0;
    }

    // 解锁播放权限（精确匹配）
    if ([key isEqualToString:@"play_auth"] ||
        [key isEqualToString:@"canPlayVideo"]) {
        return @1;
    }

    // 关闭广告（仅精确匹配广告相关key，不影响其他字段）
    if ([key isEqualToString:@"has_ad"] ||
        [key isEqualToString:@"ad_status"] ||
        [key isEqualToString:@"show_splash_ad"] ||
        [key isEqualToString:@"showLaunchAd"] ||
        [key isEqualToString:@"needShowAd"]) {
        return @0;
    }

    // 解锁下载/清晰度（精确匹配）
    if ([key isEqualToString:@"can_download"] ||
        [key isEqualToString:@"max_quality"]) {
        return @1;
    }

    // 永久VIP过期时间（精确匹配）
    if ([key isEqualToString:@"vip_expire_time"]) {
        return @4070880000;
    }

    return res;
}
%end

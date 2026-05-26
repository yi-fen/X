#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor
{
    NSLog(@"人人追剧 原生重写补丁加载成功");
}

// 全局拦截字典取值，原生复刻JS全部改号VIP逻辑
%hook NSDictionary
- (id)objectForKey:(id)aKey
{
    id orig = %orig;
    if (!aKey) return orig;

    NSString *key = (NSString *)aKey;

    // ========== 完全复刻原JS脚本规则 ==========
    // 1. 强制替换昵称 为电报频道
    if ([key isEqualToString:@"nickname"] || [key isEqualToString:@"username"])
    {
        return @"https://t.me/onz3v_channel";
    }

    // 2. VIP 状态全开
    if ([key isEqualToString:@"is_vip"] ||
        [key isEqualToString:@"vip_status"] ||
        [key isEqualToString:@"is_forever_vip"])
    {
        return @1;
    }

    // 3. 无需VIP、关闭付费限制
    if ([key isEqualToString:@"vip_need"] ||
        [key isEqualToString:@"needVip"])
    {
        return @0;
    }

    // 4. 强制允许播放权限
    if ([key isEqualToString:@"play_auth"])
    {
        return @1;
    }

    // 5. 全部广告关闭
    if ([key isEqualToString:@"ad_status"] ||
        [key isEqualToString:@"has_ad"] ||
        [key isEqualToString:@"show_splash_ad"] ||
        [key isEqualToString:@"splash_ad"] ||
        [key isEqualToString:@"show_ad"])
    {
        return @0;
    }

    // 6. 解锁下载、最高清晰度
    if ([key isEqualToString:@"can_download"] ||
        [key isEqualToString:@"max_quality"])
    {
        return @1;
    }

    // 7. 永久VIP过期时间
    if ([key isEqualToString:@"vip_expire_time"])
    {
        return @4070880000;
    }

    return orig;
}
%end

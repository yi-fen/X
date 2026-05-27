#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"人人追剧 原生补丁加载成功");
}

// 全局拦截所有字典取值，强制篡改VIP/广告（基于原版修复）
%hook NSDictionary
- (id)objectForKey:(id)aKey
{
    id res = %orig;
    if (!aKey) return res;
    NSString *key = (NSString *)aKey;

    // ========== 已删除：昵称替换逻辑（保留APP默认昵称） ==========

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

    // 全部广告关闭（仅精准匹配，删除危险的 containsString 模糊查询）
    if ([key isEqualToString:@"show_splash"] ||
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

// ========== 已完整删除：NSNumber 全局BOOL篡改（解决UI卡死） ==========
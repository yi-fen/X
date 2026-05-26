#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const targetHost = @"api.rrzj666.com";

%ctor {
    NSLog(@"RenRenZhuiJu 终极双保险补丁加载完成");
}

// 方案1：保留NSJSONSerialization拦截（防万一）
%hook NSJSONSerialization
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error
{
    id origJson = %orig;
    
    if (!origJson) return origJson;
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!str || ![str containsString:targetHost]) {
        return origJson;
    }
    
    if ([origJson isKindOfClass:NSMutableDictionary.class]) {
        NSMutableDictionary *json = (NSMutableDictionary *)origJson;
        if (json[@"data"] && [json[@"data"] isKindOfClass:NSMutableDictionary.class]) {
            NSMutableDictionary *d = json[@"data"];
            
            // 篡改昵称
            d[@"nickname"] = @"https://t.me/onz3v_channel";
            d[@"username"] = @"https://t.me/onz3v_channel";
            
            // 篡改VIP状态
            d[@"is_vip"] = @1;
            d[@"vip_status"] = @1;
            d[@"vip_need"] = @0;
            d[@"play_auth"] = @1;
            d[@"is_forever_vip"] = @1;
            d[@"vip_expire_time"] = @(4070880000);
            
            // 篡改广告开关
            d[@"ad_status"] = @0;
            d[@"has_ad"] = @0;
            d[@"show_splash_ad"] = @0;
            
            // 篡改权限
            d[@"can_download"] = @1;
            d[@"max_quality"] = @4;
        }
    }
    
    return origJson;
}
%end

// 方案2：全局拦截所有字典取值（终极兜底，必生效）
%hook NSDictionary
- (id)objectForKey:(id)aKey
{
    id orig = %orig;
    
    // 强制篡改所有VIP/昵称/广告相关键值对
    if ([aKey isKindOfClass:NSString.class]) {
        NSString *key = (NSString *)aKey;
        
        // 昵称/用户名
        if ([key isEqualToString:@"nickname"] || [key isEqualToString:@"username"]) {
            return @"https://t.me/onz3v_channel";
        }
        
        // VIP状态
        if ([key isEqualToString:@"is_vip"] || [key isEqualToString:@"vip_status"] || [key isEqualToString:@"is_forever_vip"]) {
            return @1;
        }
        
        // 非VIP/需要VIP
        if ([key isEqualToString:@"vip_need"] || [key isEqualToString:@"needVip"]) {
            return @0;
        }
        
        // 播放权限
        if ([key isEqualToString:@"play_auth"]) {
            return @1;
        }
        
        // 广告开关
        if ([key isEqualToString:@"ad_status"] || [key isEqualToString:@"has_ad"] || 
            [key isEqualToString:@"show_splash_ad"] || [key isEqualToString:@"splash_ad_enable"]) {
            return @0;
        }
        
        // 下载/清晰度
        if ([key isEqualToString:@"can_download"] || [key isEqualToString:@"max_quality"]) {
            return @1;
        }
    }
    
    return orig;
}
%end

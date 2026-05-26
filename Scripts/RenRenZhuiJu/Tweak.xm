#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const targetHost = @"api.rrzj666.com";

%ctor {
    NSLog(@"RenRenZhuiJu 网络拦截加载成功");
}

// 通杀Hook所有JSON解析，网络返回那一刻篡改
%hook NSJSONSerialization
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error
{
    id origJson = %orig;
    
    if (!origJson) return origJson;
    
    // 判断是否是目标接口的JSON
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!str || ![str containsString:targetHost]) {
        return origJson;
    }
    
    // 篡改响应（纯网络层，不是本地硬编码）
    if ([origJson isKindOfClass:NSMutableDictionary.class]) {
        NSMutableDictionary *json = (NSMutableDictionary *)origJson;
        if (json[@"data"] && [json[@"data"] isKindOfClass:NSMutableDictionary.class]) {
            NSMutableDictionary *d = json[@"data"];
            
            // 网络层篡改昵称（和Surge一致，不是本地写死）
            d[@"nickname"] = @"https://t.me/onz3v_channel";
            d[@"username"] = @"https://t.me/onz3v_channel";
            
            // 网络层全开VIP
            d[@"is_vip"] = @1;
            d[@"vip_status"] = @1;
            d[@"vip_need"] = @0;
            d[@"play_auth"] = @1;
            d[@"is_forever_vip"] = @1;
            d[@"vip_expire_time"] = @(4070880000);
            
            // 网络层关广告
            d[@"ad_status"] = @0;
            d[@"has_ad"] = @0;
            d[@"show_splash_ad"] = @0;
            
            // 解锁权限
            d[@"can_download"] = @1;
            d[@"max_quality"] = @4;
        }
    }
    
    return origJson;
}
%end

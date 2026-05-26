#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>

static NSString *const targetHost = @"api.rrzj666";

// 底层CFHTTPMessage 私有类 Hook（标准Theos语法，无自定义宏）
%hook __CFHTTPMessage
- (NSData *)copyHTTPBody
{
    NSData *oriData = %orig;
    if (!oriData) return oriData;

    // 拿到请求URL
    CFURLRef urlRef = CFHTTPMessageCopyRequestURL((__bridge CFHTTPMessageRef)self);
    if (!urlRef) return oriData;

    NSString *urlStr = (__bridge_transfer NSString *)CFURLGetString(urlRef);
    
    // 只拦截目标接口
    if ([urlStr containsString:targetHost])
    {
        NSError *err = nil;
        NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:oriData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&err];
        if (err || !json || ![json isKindOfClass:NSMutableDictionary])
            return oriData;

        // 完全复刻 Surge 脚本篡改逻辑
        if (json[@"data"] && [json[@"data"] isKindOfClass:NSMutableDictionary.class])
        {
            NSMutableDictionary *data = json[@"data"];
            
            // 改昵称（启动立刻生效）
            data[@"nickname"] = @"https://t.me/onz3v_channel";
            data[@"username"] = @"https://t.me/onz3v_channel";
            
            // 全开VIP
            data[@"is_vip"] = @1;
            data[@"vip_status"] = @1;
            data[@"vip_need"] = @0;
            data[@"play_auth"] = @1;
            data[@"is_forever_vip"] = @1;
            data[@"vip_expire_time"] = @(4070880000);
            
            // 关广告
            data[@"ad_status"] = @0;
            data[@"has_ad"] = @0;
            data[@"show_splash_ad"] = @0;
            
            // 解锁下载/清晰度
            data[@"can_download"] = @1;
            data[@"max_quality"] = @4;
        }

        // 重新打包篡改后的JSON
        NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&err];
        if (newData) return newData;
    }

    return oriData;
}
%end

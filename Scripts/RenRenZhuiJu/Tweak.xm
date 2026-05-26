#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// 全局缓存需要篡改的域名&缓存原始响应
static NSString *const targetHost = @"api.rrzj666.com";
static NSMutableDictionary *responseCache;

%ctor
{
    responseCache = [[NSMutableDictionary alloc] init];
    NSLog(@"CFNetwork底层拦截插件加载完成");
}

// Hook 底层CFNetwork HTTP响应接收
%hook CFHTTPMessage
+ (void)initialize
{
    Class cls = objc_getClass("__CFHTTPMessage");
    if (!cls) return;

    // Hook 拷贝响应数据底层方法
    METHook(cls, @selector(copyHTTPBody), IMP_HOOK(NSData *, id self, SEL _cmd){
        NSData *origData = %orig;
        if (!origData) return origData;

        // 取出当前请求Host
        CFHTTPMessageRef msg = (__bridge CFHTTPMessageRef)self;
        CFURLRef urlRef = CFHTTPMessageCopyRequestURL(msg);
        if (!urlRef) return origData;

        NSString *urlStr = (__bridge_transfer NSString *)CFURLGetString(urlRef);
        
        // 只匹配目标域名
        if ([urlStr containsString:targetHost])
        {
            NSLog(@"底层拦截到接口: %@", urlStr);
            
            // 解析JSON并篡改（和Surge脚本完全一致逻辑）
            NSError *err;
            NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:origData options:NSJSONReadingMutableContainers error:&err];
            
            if (!err && json && [json isKindOfClass:NSMutableDictionary.class])
            {
                NSMutableDictionary *data = json[@"data"];
                if (data && [data isKindOfClass:NSMutableDictionary.class])
                {
                    // 1. 强制替换昵称（和Surge一致）
                    data[@"nickname"] = @"https://t.me/onz3v_channel";
                    data[@"username"] = @"https://t.me/onz3v_channel";
                    
                    // 2. 全开VIP权限
                    data[@"is_vip"] = @1;
                    data[@"vip_status"] = @1;
                    data[@"vip_need"] = @0;
                    data[@"play_auth"] = @1;
                    data[@"is_forever_vip"] = @1;
                    data[@"vip_expire_time"] = @(4070880000);
                    
                    // 3. 关闭所有广告
                    data[@"ad_status"] = @0;
                    data[@"has_ad"] = @0;
                    data[@"show_splash_ad"] = @0;
                    
                    // 4. 解锁下载/清晰度
                    data[@"can_download"] = @1;
                    data[@"max_quality"] = @4;
                }
                
                // 重新生成篡改后的二进制数据
                NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&err];
                if (newData)
                {
                    NSLog(@"已完成网络层篡改：昵称/VIP/广告已生效");
                    return newData;
                }
            }
        }
        
        return origData;
    });
}
%end

// 通用Method Hook宏（适配底层CF类型）
#define METHook(cls, sel, imp) method_setImplementation(class_getInstanceMethod(cls, sel), imp)

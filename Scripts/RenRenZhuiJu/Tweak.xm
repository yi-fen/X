#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface RRZJURLProtocol : NSURLProtocol <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@end

@implementation RRZJURLProtocol

static NSURLSession *session;
static RRZJURLProtocol *sharedDelegate;

+ (void)load {
    [super load];
    NSLog(@"✅ RRZJ Tweak 加载成功");
    
    // 1. 强制替换所有NSURLSessionConfiguration的protocolClasses（核心修复）
    Class configClass = [NSURLSessionConfiguration class];
    SEL defaultConfigSEL = @selector(defaultSessionConfiguration);
    Method originalMethod = class_getClassMethod(configClass, defaultConfigSEL);
    IMP originalIMP = method_getImplementation(originalMethod);
    
    IMP hookedIMP = imp_implementationWithBlock(^id(id self, SEL _cmd) {
        NSURLSessionConfiguration *config = ((id (*)(id, SEL))originalIMP)(self, _cmd);
        // 把我们的协议插到最前面，强制最高优先级
        NSMutableArray *protocols = [config.protocolClasses mutableCopy];
        [protocols insertObject:[RRZJURLProtocol class] atIndex:0];
        config.protocolClasses = protocols;
        NSLog(@"✅ 强制插入URLProtocol到最高优先级");
        return config;
    });
    
    method_setImplementation(originalMethod, hookedIMP);
    
    // 2. 注册全局URLProtocol作为备份
    [NSURLProtocol registerClass:[RRZJURLProtocol class]];
    
    // 3. 初始化共享Session
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDelegate = [[RRZJURLProtocol alloc] init];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config delegate:sharedDelegate delegateQueue:nil];
    });
    
    NSLog(@"✅ 所有拦截初始化完成");
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *urlString = request.URL.absoluteString.lowercaseString;
    NSLog(@"🔍 拦截到请求：%@", urlString);
    
    // 只拦截目标域名
    if ([urlString containsString:@"api.rrzj666.com"] ||
        [urlString containsString:@"ad.rrzj666.com"] ||
        [urlString containsString:@"splash.rrzj666.com"]) {
        if ([NSURLProtocol propertyForKey:@"RRZJHandled" inRequest:request]) {
            return NO;
        }
        NSLog(@"✅ 命中目标请求，开始处理");
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"RRZJHandled" inRequest:mutableRequest];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:mutableRequest];
    [task resume];
}

- (void)stopLoading {}

#pragma mark - 响应修改（和原MITM完全一致）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
    
    if (!jsonError && jsonObject) {
        NSLog(@"✅ 收到响应，开始修改");
        
        if ([jsonObject isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *json = (NSMutableDictionary *)jsonObject;
            
            // 全局VIP状态
            if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
                NSMutableDictionary *dataDict = json[@"data"];
                dataDict[@"is_vip"] = @(1);
                dataDict[@"vip_need"] = @(0);
                dataDict[@"play_auth"] = @(1);
                dataDict[@"vip_status"] = @(1);
                dataDict[@"is_forever_vip"] = @(1);
                dataDict[@"vip_expire_time"] = @(4070880000);
                dataDict[@"nickname"] = @"https://t.me/onz3v_channel";
                dataDict[@"ad_status"] = @(0);
                dataDict[@"has_ad"] = @(0);
                dataDict[@"show_splash_ad"] = @(0);
                dataDict[@"can_download"] = @(1);
                dataDict[@"max_quality"] = @(4);
                dataDict[@"background_play"] = @(1);
                NSLog(@"✅ VIP状态修改成功");
            }
            
            // 视频列表/播放接口
            if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray *dataArray = json[@"data"];
                for (NSInteger i=0; i<dataArray.count; i++) {
                    if ([dataArray[i] isKindOfClass:[NSMutableDictionary class]]) {
                        NSMutableDictionary *item = dataArray[i];
                        item[@"is_vip"] = @(0);
                        item[@"vip_need"] = @(0);
                        item[@"play_auth"] = @(1);
                        item[@"ad_status"] = @(0);
                    }
                }
                NSLog(@"✅ 视频列表修改成功");
            }
            
            // 清空所有广告
            if (json[@"ad_list"]) json[@"ad_list"] = @[];
            if (json[@"splash_ad"]) json[@"splash_ad"] = @{};
            json[@"show_ad"] = @(0);
        }
        
        NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
        if (modifiedData) {
            [self.client URLProtocol:self didLoadData:modifiedData];
            NSLog(@"✅ 响应修改完成，返回给客户端");
            return;
        }
    }
    
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

@end

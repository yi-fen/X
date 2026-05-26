#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface RRZJURLProtocol : NSURLProtocol <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@end

@implementation RRZJURLProtocol

static NSURLSession *session;
static RRZJURLProtocol *sharedDelegate;

+ (void)load {
    [super load];
    // 注册自定义URLProtocol，全局拦截所有HTTP/HTTPS请求
    [NSURLProtocol registerClass:[RRZJURLProtocol class]];
    
    // 初始化共享delegate和Session（修复编译错误：使用实例对象作为delegate）
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDelegate = [[RRZJURLProtocol alloc] init];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config delegate:sharedDelegate delegateQueue:nil];
    });
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *urlString = request.URL.absoluteString.lowercaseString;
    // 只拦截我们需要的域名，避免影响其他请求
    if ([urlString containsString:@"api.rrzj666.com"] ||
        [urlString containsString:@"ad.rrzj666.com"] ||
        [urlString containsString:@"splash.rrzj666.com"]) {
        // 避免循环拦截
        if ([NSURLProtocol propertyForKey:@"RRZJHandled" inRequest:request]) {
            return NO;
        }
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

- (void)stopLoading {
    // 不需要额外处理
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSMutableData *mutableData = [data mutableCopy];
    
    // 100%复刻原作者MITM脚本的响应修改逻辑
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:mutableData options:NSJSONReadingMutableContainers error:&jsonError];
    
    if (!jsonError && jsonObject) {
        // 修改全局VIP状态和用户信息（和原脚本完全一致）
        if ([jsonObject isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *json = (NSMutableDictionary *)jsonObject;
            
            if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
                NSMutableDictionary *dataDict = json[@"data"];
                
                // 原脚本核心修改：VIP状态
                dataDict[@"is_vip"] = @(1);
                dataDict[@"vip_need"] = @(0);
                dataDict[@"play_auth"] = @(1);
                dataDict[@"vip_status"] = @(1);
                dataDict[@"is_forever_vip"] = @(1);
                dataDict[@"vip_expire_time"] = @(4070880000); // 2099-12-31
                
                // 原脚本修改：用户名替换为频道地址
                dataDict[@"nickname"] = @"https://t.me/onz3v_channel";
                dataDict[@"username"] = @"https://t.me/onz3v_channel";
                
                // 关闭所有广告
                dataDict[@"ad_status"] = @(0);
                dataDict[@"has_ad"] = @(0);
                dataDict[@"show_splash_ad"] = @(0);
                dataDict[@"splash_ad_enable"] = @(0);
                
                // 解锁权限
                dataDict[@"can_download"] = @(1);
                dataDict[@"max_quality"] = @(4);
                dataDict[@"background_play"] = @(1);
            }
            
            // 修改视频播放/详情接口
            if (json[@"data"] && [json[@"data"] isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray *dataArray = json[@"data"];
                for (NSInteger i=0; i<dataArray.count; i++) {
                    if ([dataArray[i] isKindOfClass:[NSMutableDictionary class]]) {
                        NSMutableDictionary *item = dataArray[i];
                        item[@"is_vip"] = @(0);
                        item[@"vip_need"] = @(0);
                        item[@"play_auth"] = @(1);
                        item[@"ad_status"] = @(0);
                        item[@"can_download"] = @(1);
                    }
                }
            }
            
            // 清空所有广告
            if (json[@"ad_list"]) json[@"ad_list"] = @[];
            if (json[@"splash_ad"]) json[@"splash_ad"] = @{};
            if (json[@"advertisement"]) json[@"advertisement"] = @{};
            json[@"show_ad"] = @(0);
            json[@"ad_enable"] = @(0);
        }
        
        // 重新序列化修改后的JSON
        NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
        if (modifiedData) {
            mutableData = [modifiedData mutableCopy];
        }
    }
    
    // 将修改后的数据返回给客户端
    [self.client URLProtocol:self didLoadData:mutableData];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

@end

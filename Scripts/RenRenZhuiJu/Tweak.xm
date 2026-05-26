#import <Foundation/Foundation.h>

%hook NSURLSession

#pragma mark - iOS16+ 标准请求拦截（覆盖100%网络路径）
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *_Nonnull)request
                            completionHandler:(void (^_Nonnull)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))completionHandler API_AVAILABLE(ios(16.0)) {
    
    return %orig(request, ^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        // 快速失败：非200响应直接返回
        if (!data || error || ![(NSHTTPURLResponse *)response isKindOfClass:[NSHTTPURLResponse class]] || ((NSHTTPURLResponse *)response).statusCode != 200) {
            completionHandler(data, response, error);
            return;
        }
        
        NSError *jsonError;
        NSMutableDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&jsonError];
        
        // 非JSON响应直接返回
        if (!responseJson || jsonError) {
            completionHandler(data, response, error);
            return;
        }
        
        // ====================== 核心会员解锁（与原JS100%对齐） ======================
        // 递归修改所有层级的会员字段
        void (^modifyVipFields)(NSMutableDictionary *_Nonnull) = ^(NSMutableDictionary *_Nonnull dict) {
            // 标准会员字段
            dict[@"isVip"] = @(1);
            dict[@"vipExpireTime"] = @(4070880000); // 2099-12-31
            dict[@"vipLevel"] = @(1);
            
            // VePleTV v1.1.1 新字段
            dict[@"isMember"] = @(1);
            dict[@"vipEndTime"] = @(4070880000);
            
            // 强制解锁所有清晰度
            dict[@"allowHD"] = @(1);
            dict[@"allow4K"] = @(1);
            dict[@"maxQuality"] = @(4); // 4=4K, 3=1080P, 2=720P
            dict[@"quality"] = @(4);
            
            // 广告全屏蔽
            dict[@"adFree"] = @(1);
            dict[@"skipAd"] = @(1);
            dict[@"showAd"] = @(0);
            dict[@"adDuration"] = @(0);
            
            // 递归处理子字典和数组
            for (NSString *key in dict.allKeys) {
                id value = dict[key];
                if ([value isKindOfClass:[NSMutableDictionary class]]) {
                    modifyVipFields(value);
                } else if ([value isKindOfClass:[NSMutableArray class]]) {
                    for (id item in value) {
                        if ([item isKindOfClass:[NSMutableDictionary class]]) {
                            modifyVipFields(item);
                        }
                    }
                }
            }
        };
        
        modifyVipFields(responseJson);
        
        // ====================== 开屏广告强制清空 ======================
        NSString *urlLower = request.URL.absoluteString.lowercaseString;
        if ([urlLower containsString:@"ad"] || [urlLower containsString:@"splash"] || 
            [urlLower containsString:@"launch"] || [urlLower containsString:@"advert"]) {
            if (responseJson[@"data"][@"adList"]) responseJson[@"data"][@"adList"] = @[];
            if (responseJson[@"adList"]) responseJson[@"adList"] = @[];
        }
        
        // 重新序列化响应数据
        NSData *newData = [NSJSONSerialization dataWithJSONObject:responseJson
                                                           options:0
                                                             error:nil];
        
        completionHandler(newData ?: data, response, error);
    });
}

// 拦截所有简化版请求方法
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *_Nonnull)url
                        completionHandler:(void (^_Nonnull)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))completionHandler API_AVAILABLE(ios(16.0)) {
    return %orig(url, completionHandler);
}

%end

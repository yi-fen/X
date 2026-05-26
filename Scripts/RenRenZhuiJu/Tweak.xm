#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            completionHandler(data, response, error);
            return;
        }
        
        NSError *jsonError;
        NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data 
                                                                    options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves 
                                                                      error:&jsonError];
        
        if (!json || jsonError) {
            completionHandler(data, response, error);
            return;
        }
        
        // 递归遍历所有字典，修改所有会员相关字段
        void (^modifyVipFields)(NSMutableDictionary *) = ^(NSMutableDictionary *dict) {
            // 新字段（v1.1.1 核心）
            if (dict[@"isMember"]) dict[@"isMember"] = @(1);
            if (dict[@"vipEndTime"]) dict[@"vipEndTime"] = @(4070880000);
            if (dict[@"vipLevel"]) dict[@"vipLevel"] = @(1);
            // 旧字段兼容
            if (dict[@"isVip"]) dict[@"isVip"] = @(1);
            if (dict[@"vipExpireTime"]) dict[@"vipExpireTime"] = @(4070880000);
            // 广告全屏蔽
            if (dict[@"adFree"]) dict[@"adFree"] = @(1);
            if (dict[@"skipAd"]) dict[@"skipAd"] = @(1);
            if (dict[@"showAd"]) dict[@"showAd"] = @(0);
            if (dict[@"adDuration"]) dict[@"adDuration"] = @(0);
            
            // 递归处理子层级
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
        
        modifyVipFields(json);
        
        // 开屏广告强制清空
        NSString *urlString = request.URL.absoluteString.lowercaseString;
        if ([urlString containsString:@"ad"] || 
            [urlString containsString:@"splash"] || 
            [urlString containsString:@"launch"] ||
            [urlString containsString:@"advert"]) {
            if (json[@"data"][@"adList"]) json[@"data"][@"adList"] = @[];
            if (json[@"adList"]) json[@"adList"] = @[];
            if (json[@"data"][@"hasAd"]) json[@"data"][@"hasAd"] = @(0);
            if (json[@"hasAd"]) json[@"hasAd"] = @(0);
        }
        
        NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        completionHandler(newData ?: data, response, error);
    });
}

%end

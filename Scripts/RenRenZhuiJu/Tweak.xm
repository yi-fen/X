#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            completionHandler(data, response, error);
            return;
        }

        NSError *jsonError;
        NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (!json || jsonError) {
            completionHandler(data, response, error);
            return;
        }

        // 处理根层级
        if (json[@"isMember"]) json[@"isMember"] = @(1);
        if (json[@"vipEndTime"]) json[@"vipEndTime"] = @(4070880000);
        if (json[@"vipLevel"]) json[@"vipLevel"] = @(1);
        if (json[@"isVip"]) json[@"isVip"] = @(1);
        if (json[@"vipExpireTime"]) json[@"vipExpireTime"] = @(4070880000);
        if (json[@"adFree"]) json[@"adFree"] = @(1);
        if (json[@"skipAd"]) json[@"skipAd"] = @(1);
        if (json[@"showAd"]) json[@"showAd"] = @(0);

        // 处理data字典（最常见）
        if ([json[@"data"] isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *dataDict = json[@"data"];
            if (dataDict[@"isMember"]) dataDict[@"isMember"] = @(1);
            if (dataDict[@"vipEndTime"]) dataDict[@"vipEndTime"] = @(4070880000);
            if (dataDict[@"vipLevel"]) dataDict[@"vipLevel"] = @(1);
            if (dataDict[@"isVip"]) dataDict[@"isVip"] = @(1);
            if (dataDict[@"vipExpireTime"]) dataDict[@"vipExpireTime"] = @(4070880000);
            if (dataDict[@"adFree"]) dataDict[@"adFree"] = @(1);
            if (dataDict[@"skipAd"]) dataDict[@"skipAd"] = @(1);
            if (dataDict[@"showAd"]) dataDict[@"showAd"] = @(0);
            if (dataDict[@"adList"]) dataDict[@"adList"] = @[];
        }

        // 处理data数组
        if ([json[@"data"] isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *dataArray = json[@"data"];
            for (NSMutableDictionary *item in dataArray) {
                if ([item isKindOfClass:[NSMutableDictionary class]]) {
                    if (item[@"isMember"]) item[@"isMember"] = @(1);
                    if (item[@"vipEndTime"]) item[@"vipEndTime"] = @(4070880000);
                    if (item[@"vipLevel"]) item[@"vipLevel"] = @(1);
                    if (item[@"isVip"]) item[@"isVip"] = @(1);
                }
            }
        }

        // 开屏广告强制清空
        NSString *url = request.URL.absoluteString.lowercaseString;
        if ([url containsString:@"splash"] || [url containsString:@"launch"]) {
            if (json[@"data"]) json[@"data"] = [NSMutableDictionary dictionary];
        }

        NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        completionHandler(newData ?: data, response, error);
    });
}

%end

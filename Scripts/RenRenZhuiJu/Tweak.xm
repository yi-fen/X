#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler
{
    return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            completionHandler(data, response, error);
            return;
        }

        NSError *jsonError;
        NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&jsonError];
        if (!json || jsonError) {
            completionHandler(data, response, error);
            return;
        }

        if (json[@"data"]) {
            NSMutableDictionary *dataDict = json[@"data"];
            
            // 会员解锁（与JS完全一致）
            dataDict[@"isVip"] = @1;
            dataDict[@"isMember"] = @1;
            dataDict[@"vipLevel"] = @1;
            dataDict[@"vipExpireTime"] = @4070880000;
            dataDict[@"vipEndTime"] = @4070880000;

            // 解锁全部清晰度
            dataDict[@"allowHD"] = @1;
            dataDict[@"allow4K"] = @1;
            dataDict[@"maxQuality"] = @4;
            dataDict[@"quality"] = @4;

            // 关闭广告
            dataDict[@"adFree"] = @1;
            dataDict[@"skipAd"] = @1;
            dataDict[@"showAd"] = @0;
            dataDict[@"adList"] = @[];
        }

        NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        completionHandler(newData ?: data, response, error);
    });
}

%end

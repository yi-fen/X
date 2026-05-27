#import <Foundation/Foundation.h>

%ctor {
    NSLog(@"✅ 人人追剧 VePleTV 补丁加载成功");
}

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

        // 只修改自己APP的JSON，不碰系统任何东西
        NSMutableDictionary *dataDict = json[@"data"];
        if (dataDict && [dataDict isKindOfClass:[NSMutableDictionary class]]) {

            // VIP 核心（必生效）
            dataDict[@"isVip"] = @1;
            dataDict[@"isMember"] = @1;
            dataDict[@"vipLevel"] = @1;
            dataDict[@"vipExpireTime"] = @4070880000;
            dataDict[@"vipEndTime"] = @4070880000;

            // 解锁清晰度
            dataDict[@"allowHD"] = @1;
            dataDict[@"allow4K"] = @1;
            dataDict[@"maxQuality"] = @4;
            dataDict[@"quality"] = @4;

            // 广告关闭
            dataDict[@"adFree"] = @1;
            dataDict[@"skipAd"] = @1;
            dataDict[@"showAd"] = @0;
            dataDict[@"adList"] = @[];

            // 播放权限
            dataDict[@"play_auth"] = @1;
            dataDict[@"vip_need"] = @0;
        }

        NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        completionHandler(newData ?: data, response, error);
    });
}

%end

#import <Foundation/Foundation.h>

@interface NSURLSessionDataTask (Private)
@property (nonatomic, copy) void (^completionHandler)(NSData *, NSURLResponse *, NSError *);
@end

%hook NSURLSessionDataTask

- (void)setCompletionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    void (^wrappedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
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

        // 解锁VIP
        if (json[@"data"][@"isMember"]) json[@"data"][@"isMember"] = @(1);
        if (json[@"data"][@"vipEndTime"]) json[@"data"][@"vipEndTime"] = @(4070880000);
        if (json[@"data"][@"vipLevel"]) json[@"data"][@"vipLevel"] = @(1);
        if (json[@"data"][@"isVip"]) json[@"data"][@"isVip"] = @(1);
        if (json[@"data"][@"vipExpireTime"]) json[@"data"][@"vipExpireTime"] = @(4070880000);

        // 屏蔽广告
        if (json[@"data"][@"adFree"]) json[@"data"][@"adFree"] = @(1);
        if (json[@"data"][@"skipAd"]) json[@"data"][@"skipAd"] = @(1);
        if (json[@"data"][@"showAd"]) json[@"data"][@"showAd"] = @(0);
        if (json[@"data"][@"adList"]) json[@"data"][@"adList"] = @[];

        NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        completionHandler(newData ?: data, response, error);
    };

    %orig(wrappedHandler);
}

%end

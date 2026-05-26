#import <Foundation/Foundation.h>

%hook NSURLSession

- (id)dataTaskWithRequest:(id)request completionHandler:(id)completionHandler {
    id newCompletion = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (json) {
                NSMutableDictionary *dataDict = json[@"data"];
                if (dataDict && [dataDict isKindOfClass:[NSMutableDictionary class]]) {
                    dataDict[@"isVip"] = @1;
                    dataDict[@"isMember"] = @1;
                    dataDict[@"vipLevel"] = @1;
                    dataDict[@"vipExpireTime"] = @4070880000;
                    dataDict[@"vipEndTime"] = @4070880000;
                    dataDict[@"allowHD"] = @1;
                    dataDict[@"allow4K"] = @1;
                    dataDict[@"maxQuality"] = @4;
                    dataDict[@"quality"] = @4;
                    dataDict[@"adFree"] = @1;
                    dataDict[@"skipAd"] = @1;
                    dataDict[@"showAd"] = @0;
                    dataDict[@"adList"] = @[];
                }
                NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                if (newData) data = newData;
            }
        }
        completionHandler(data, response, error);
    };
    return %orig(request, newCompletion);
}

%end

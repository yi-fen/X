#import <Foundation/Foundation.h>

%hook NSURLSessionDataTask

- (void)resume {
    %orig;
    
    // 全局拦截所有网络响应，不依赖APP内部类名，兼容性最强
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NSURLSessionDataTaskDidCompleteNotification" 
                                                      object:self 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification *note) {
        
        // 获取原始响应数据
        NSData *originalData = note.userInfo[@"NSURLSessionDataTaskResponseData"];
        if (!originalData) return;
        
        // 尝试解析JSON
        NSError *error;
        NSMutableDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:originalData 
                                                                            options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves 
                                                                              error:&error];
        
        // 非JSON响应直接跳过
        if (!responseJson || error) return;
        
        // ====================== v1.1.1 核心会员字段修正 ======================
        // 原字段 isVip → 改为 isMember
        // 原字段 vipExpireTime → 改为 vipEndTime
        // 新增必填字段 vipLevel = 1
        // 同时保留旧字段兼容所有页面
        if (responseJson[@"data"]) {
            // 新字段（v1.1.1 主要使用）
            responseJson[@"data"][@"isMember"] = @(1);
            responseJson[@"data"][@"vipEndTime"] = @(4070880000); // 2099-12-31 过期
            responseJson[@"data"][@"vipLevel"] = @(1);
            
            // 旧字段（部分残留页面使用）
            responseJson[@"data"][@"isVip"] = @(1);
            responseJson[@"data"][@"vipExpireTime"] = @(4070880000);
            
            // 额外解锁广告跳过权限
            responseJson[@"data"][@"adFree"] = @(1);
            responseJson[@"data"][@"skipAd"] = @(1);
        }
        
        // 处理部分接口直接返回data数组的情况
        if ([responseJson[@"data"] isKindOfClass:[NSArray class]]) {
            for (NSMutableDictionary *item in responseJson[@"data"]) {
                if ([item isKindOfClass:[NSMutableDictionary class]]) {
                    item[@"isMember"] = @(1);
                    item[@"vipEndTime"] = @(4070880000);
                    item[@"vipLevel"] = @(1);
                    item[@"isVip"] = @(1);
                }
            }
        }
        
        // 重新序列化并替换响应数据
        NSData *newData = [NSJSONSerialization dataWithJSONObject:responseJson 
                                                           options:0 
                                                             error:nil];
        if (newData) {
            [note.userInfo setValue:newData forKey:@"NSURLSessionDataTaskResponseData"];
        }
    }];
}

%end

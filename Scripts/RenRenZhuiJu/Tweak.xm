#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"VePleTV 纯净版补丁加载成功");
}

// 1. 【VIP状态】核心拦截（已生效部分优化，无多余代码）
%hook NSObject
- (BOOL)isVip { return YES; }
- (BOOL)vipStatus { return YES; }
- (BOOL)vipAuth { return YES; }
- (BOOL)hasVipPrivilege { return YES; }

- (BOOL)vipNeed { return NO; }
- (BOOL)needVip { return NO; }

- (BOOL)playAuth { return YES; }
- (BOOL)canPlayVideo { return YES; }
%end

// 2. 【广告拦截】双保险方案（彻底关闭开屏/插屏广告）
%hook NSObject
// 拦截广告判断方法，直接返回"不需要显示"
- (BOOL)hasAd { return NO; }
- (BOOL)needShowAd { return NO; }
- (BOOL)showSplashAd { return NO; }
- (BOOL)showLaunchAd { return NO; }
- (BOOL)shouldShowAd { return NO; }
- (BOOL)isAdEnabled { return NO; }
- (BOOL)showInterstitialAd { return NO; }
- (BOOL)showVideoAd { return NO; }
%end

// 3. 【防广告显示】直接过滤所有广告类视图（双重保险，确保广告无法显示）
%hook UIView
- (void)addSubview:(UIView *)view {
    NSString *className = NSStringFromClass([view class]);
    // 过滤所有带Ad/AD的广告类视图，直接不添加到界面
    if ([className containsString:@"Ad"] || [className containsString:@"AD"] || [className containsString:@"ad"]) {
        NSLog(@"Blocked ad view: %@", className);
        return;
    }
    %orig;
}
%end

// 4. 【启动广告拦截】移除APP启动时的广告通知
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    // 移除所有广告相关的通知监听，防止启动广告弹出
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SplashAdShow" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LaunchAdShow" object:nil];
    return result;
}
%end

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"VePleTV 稳定版补丁加载成功");
}

// 1. 【VIP核心拦截】（之前已生效的部分，保留不变）
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

// 2. 【广告拦截】仅拦截广告判断方法，不碰UI视图，零误杀
%hook NSObject
- (BOOL)hasAd { return NO; }
- (BOOL)needShowAd { return NO; }
- (BOOL)showSplashAd { return NO; }
- (BOOL)showLaunchAd { return NO; }
- (BOOL)shouldShowAd { return NO; }
- (BOOL)isAdEnabled { return NO; }
- (BOOL)showInterstitialAd { return NO; }
- (BOOL)showVideoAd { return NO; }
%end

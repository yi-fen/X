#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"人人追剧 稳生效无卡顿补丁");
}

// 只精准Hook会员、广告布尔方法，不污染系统UI，不会卡死
%hook NSObject

// 全部强制返回会员YES
- (BOOL)isVip { return YES; }
- (BOOL)hasVip { return YES; }
- (BOOL)vip { return YES; }
- (BOOL)member { return YES; }
- (BOOL)paid { return YES; }

// 强制不需要VIP
- (BOOL)needVip { return NO; }
- (BOOL)requireVip { return NO; }

// 强制关闭开屏广告、启动广告
- (BOOL)showSplashAd { return NO; }
- (BOOL)showLaunchAd { return NO; }
- (BOOL)haveSplashAd { return NO; }
- (BOOL)launchAdEnable { return NO; }

%end

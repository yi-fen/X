# 双架构支持：arm64(A11及以下) + arm64e(A12及以上)
ARCHS = arm64 arm64e

# 最新SDK17.5编译，最低支持iOS16.0
TARGET = iphone:clang:17.5:16.0

# 编译优化：最高级别大小优化，生成最小最快的二进制
DEBUG = 0
OPTIMIZATION_LEVEL = s
STRIP = 1

# 开启所有现代Objective-C语法特性
THEOS_OBJCFLAGS = -std=gnu23 -fobjc-arc -fobjc-runtime=ios-16.0
THEOS_CFLAGS = -Wno-deprecated-declarations -Wno-unused-variable

# 目标进程
INSTALL_TARGET_PROCESSES = VePleTV

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenRenZhuiJu

RenRenZhuiJu_FILES = Tweak.xm
RenRenZhuiJu_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

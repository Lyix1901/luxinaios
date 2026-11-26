# Theos / iOS Cross-Compilation Makefile for luxinaios
TARGET := iphone:clang:latest:14.0
ARCHS := arm64

TWEAK_NAME = luxinaios

luxinaios_FILES = \
	src/entry.mm \
	src/ui/LuxinaUI.mm \
	src/core/LuxinaCore.cpp \
	src/env/LuxinaEnv.mm

luxinaios_CFLAGS = -fobjc-arc -std=c++20 -Isrc -Isrc/ui -Isrc/core -Isrc/env -Isrc/config
luxinaios_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics WebKit

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

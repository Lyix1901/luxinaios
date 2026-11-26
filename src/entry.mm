#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "core/LuxinaCore.h"
#include "config/LuxinaConfig.h"

__attribute__((constructor))
static void LuxinaEntry() {
    @autoreleasepool {
        // Wait until UIApplication is fully initialized before presenting UIKit UI
        dispatch_async(dispatch_get_main_queue(), ^{
            Luxina::Core::Initialize();
        });
    }
}

__attribute__((destructor))
static void LuxinaExit() {
    Luxina::Core::Shutdown();
}

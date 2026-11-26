#pragma once

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#include <string>

// Forward declarations
namespace Luxina::Core {
    void ExecuteScript(const std::string& script);
    void SetFPSCap(double fps);
}

@interface LuxinaFloatingButton : UIView

@property (nonatomic, copy) void (^onTapHandler)(void);
- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateStatus:(BOOL)attached;

@end

@interface LuxinaExecutorViewController : UIViewController <UITextViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) LuxinaFloatingButton *floatingButton;
- (void)toggleVisibility;
- (void)logToConsole:(NSString *)message isError:(BOOL)isError;

@end

@interface LuxinaUIManager : NSObject

+ (instancetype)sharedInstance;
- (void)initializeUI;
- (void)appendLog:(const std::string&)text isError:(bool)isError;
- (void)updateAttachmentStatus:(bool)attached;

@end

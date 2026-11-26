#pragma once

#include <string>

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface LuxinaFloatingButton : UIView

@property (nonatomic, copy) void (^onTapHandler)(void);
- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateStatus:(BOOL)attached;

@end

@interface LuxinaExecutorViewController : UIViewController <UITextViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) LuxinaFloatingButton *floatingButton;
@property (nonatomic, strong, readonly) UIView *mainCard;
@property (nonatomic, assign, readonly) BOOL isOpen;

- (void)toggleVisibility;
- (void)logToConsole:(NSString *)message isError:(BOOL)isError;

@end

@interface LuxinaPassthroughWindow : UIWindow

@property (nonatomic, weak) LuxinaFloatingButton *floatingButton;
@property (nonatomic, weak) LuxinaExecutorViewController *executorVC;

@end

@interface LuxinaUIManager : NSObject

+ (instancetype)sharedInstance;
- (void)initializeUI;
- (void)appendLog:(const std::string&)text isError:(bool)isError;
- (void)updateAttachmentStatus:(bool)attached;

@end
#endif

namespace Luxina::UI {
    void Initialize();
    void AppendLog(const std::string& text, bool isError);
    void UpdateAttachmentStatus(bool attached);
}

#import "LuxinaUI.h"
#import <QuartzCore/QuartzCore.h>
#include "../core/LuxinaCore.h"
#include "../config/LuxinaConfig.h"

// ============================================================================
// LuxinaFloatingButton Implementation
// ============================================================================
@implementation LuxinaFloatingButton {
    CGPoint _initialCenter;
    CAShapeLayer *_glowRing;
    UILabel *_iconLabel;
    UIImpactFeedbackGenerator *_haptic;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.12 alpha:0.88];
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.masksToBounds = NO;
        self.userInteractionEnabled = YES;

        // Shadow / Elevation
        self.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.45].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowRadius = 8.0;

        // Glowing border ring
        _glowRing = [CAShapeLayer layer];
        _glowRing.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
        _glowRing.strokeColor = [UIColor colorWithRed:0.35 green:0.25 blue:0.95 alpha:1.0].CGColor;
        _glowRing.fillColor = [UIColor clearColor].CGColor;
        _glowRing.lineWidth = 1.8;
        [self.layer addSublayer:_glowRing];

        // Central Icon / Logo
        _iconLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _iconLabel.text = @"⚡";
        _iconLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        _iconLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_iconLabel];

        // Gestures
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        _haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    }
    return self;
}

- (void)updateStatus:(BOOL)attached {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (attached) {
            self->_glowRing.strokeColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.55 alpha:1.0].CGColor;
            self.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.55 alpha:0.6].CGColor;
        } else {
            self->_glowRing.strokeColor = [UIColor colorWithRed:0.35 green:0.25 blue:0.95 alpha:1.0].CGColor;
            self.layer.shadowColor = [UIColor colorWithRed:0.35 green:0.25 blue:0.95 alpha:0.5].CGColor;
        }
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *superview = self.superview;
    if (!superview) return;

    CGPoint translation = [gesture translationInView:superview];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        _initialCenter = self.center;
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.center = CGPointMake(_initialCenter.x + translation.x, _initialCenter.y + translation.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];

        // Snap to nearest edge (Left or Right)
        CGRect bounds = superview.safeAreaLayoutGuide.layoutFrame;
        CGFloat halfWidth = self.bounds.size.width / 2.0;
        CGFloat halfHeight = self.bounds.size.height / 2.0;

        CGFloat targetX = (self.center.x < CGRectGetMidX(bounds)) ? bounds.origin.x + halfWidth + 8 : bounds.origin.x + bounds.size.width - halfWidth - 8;
        CGFloat targetY = MIN(MAX(self.center.y, bounds.origin.y + halfHeight + 8), bounds.origin.y + bounds.size.height - halfHeight - 8);

        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.center = CGPointMake(targetX, targetY);
        } completion:nil];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    [_haptic impactOccurred];
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(0.88, 0.88);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];

    if (self.onTapHandler) {
        self.onTapHandler();
    }
}

@end

// ============================================================================
// LuxinaExecutorViewController Implementation
// ============================================================================
@implementation LuxinaExecutorViewController {
    UIView *_mainCard;
    UIVisualEffectView *_blurEffectView;
    UIView *_headerView;
    UILabel *_titleLabel;
    UILabel *_statusBadge;
    UIButton *_closeButton;

    // Tabs
    UISegmentedControl *_tabSegments;
    UIView *_editorTabContainer;
    UIView *_scriptsTabContainer;
    UIView *_consoleTabContainer;
    UIView *_settingsTabContainer;

    // Editor Tab Elements
    UITextView *_codeTextView;
    UIButton *_executeButton;
    UIButton *_clearButton;
    UIButton *_pasteButton;

    // Console Tab Elements
    UITextView *_consoleTextView;
    UIButton *_clearConsoleButton;

    // Status
    BOOL _isOpen;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    _isOpen = NO;

    [self setupMainInterface];
}

- (void)setupMainInterface {
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;

    // Center Card dimensions (responsive for iPhone & iPad)
    CGFloat cardW = MIN(screenW * 0.90, 520.0);
    CGFloat cardH = MIN(screenH * 0.75, 420.0);

    _mainCard = [[UIView alloc] initWithFrame:CGRectMake((screenW - cardW)/2.0, (screenH - cardH)/2.0, cardW, cardH)];
    _mainCard.layer.cornerRadius = 16.0;
    _mainCard.layer.masksToBounds = YES;
    _mainCard.layer.borderColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.40 alpha:0.6].CGColor;
    _mainCard.layer.borderWidth = 1.0;
    _mainCard.alpha = 0.0;
    _mainCard.transform = CGAffineTransformMakeScale(0.85, 0.85);

    // Dark Frosted Glass Blur
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _blurEffectView.frame = _mainCard.bounds;
    _blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_mainCard addSubview:_blurEffectView];

    // Background overlay tint
    UIView *tintView = [[UIView alloc] initWithFrame:_mainCard.bounds];
    tintView.backgroundColor = [UIColor colorWithRed:0.06 green:0.07 blue:0.11 alpha:0.75];
    tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_mainCard addSubview:tintView];

    // ----------------------------------------------------
    // Header Bar
    // ----------------------------------------------------
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cardW, 48)];
    _headerView.backgroundColor = [UIColor colorWithRed:0.09 green:0.10 blue:0.16 alpha:0.65];
    [_mainCard addSubview:_headerView];

    // Prominent "luxinaios" header text
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, 160, 32)];
    _titleLabel.text = @"luxinaios";
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightHeavy];

    // Gradient accent color on title
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:@"luxinaios"];
    [attrText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0] range:NSMakeRange(0, 6)]; // "luxina"
    [attrText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.55 green:0.35 blue:1.0 alpha:1.0] range:NSMakeRange(6, 3)]; // "ios"
    _titleLabel.attributedText = attrText;
    [_headerView addSubview:_titleLabel];

    // Status Badge
    _statusBadge = [[UILabel alloc] initWithFrame:CGRectMake(180, 14, 110, 20)];
    _statusBadge.text = @"• Connected";
    _statusBadge.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    _statusBadge.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.5 alpha:1.0];
    [_headerView addSubview:_statusBadge];

    // Close Button
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.frame = CGRectMake(cardW - 40, 8, 32, 32);
    [_closeButton setTitle:@"✕" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_closeButton setTitleColor:[UIColor colorWithWhite:0.75 alpha:1.0] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_closeButton];

    // ----------------------------------------------------
    // Tab Segment Bar
    // ----------------------------------------------------
    NSArray *tabs = @[@"Editor", @"Script Hub", @"Console", @"Settings"];
    _tabSegments = [[UISegmentedControl alloc] initWithItems:tabs];
    _tabSegments.frame = CGRectMake(14, 56, cardW - 28, 28);
    _tabSegments.selectedSegmentIndex = 0;
    _tabSegments.backgroundColor = [UIColor colorWithRed:0.12 green:0.13 blue:0.20 alpha:0.7];
    [_tabSegments setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightMedium]} forState:UIControlStateNormal];
    [_tabSegments setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0], NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightBold]} forState:UIControlStateSelected];
    [_tabSegments addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [_mainCard addSubview:_tabSegments];

    // Containers for Tabs
    CGRect contentFrame = CGRectMake(14, 92, cardW - 28, cardH - 104);

    [self setupEditorTabWithFrame:contentFrame];
    [self setupScriptsTabWithFrame:contentFrame];
    [self setupConsoleTabWithFrame:contentFrame];
    [self setupSettingsTabWithFrame:contentFrame];

    [self.view addSubview:_mainCard];
}

- (void)setupEditorTabWithFrame:(CGRect)frame {
    _editorTabContainer = [[UIView alloc] initWithFrame:frame];
    _editorTabContainer.hidden = NO;

    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    CGFloat barH = 40.0;

    // Code Text Editor
    _codeTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, w, h - barH - 8)];
    _codeTextView.backgroundColor = [UIColor colorWithRed:0.04 green:0.05 blue:0.08 alpha:0.85];
    _codeTextView.textColor = [UIColor colorWithRed:0.85 green:0.90 blue:0.95 alpha:1.0];
    _codeTextView.font = [UIFont fontWithName:@"Menlo" size:13] ?: [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    _codeTextView.layer.cornerRadius = 8.0;
    _codeTextView.layer.borderColor = [UIColor colorWithRed:0.2 green:0.22 blue:0.35 alpha:0.5].CGColor;
    _codeTextView.layer.borderWidth = 1.0;
    _codeTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _codeTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    _codeTextView.text = @"-- luxinaios Luau Script Executor\nprint(\"Hello from luxinaios on iOS!\")\n";
    [_editorTabContainer addSubview:_codeTextView];

    // Toolbar buttons
    CGFloat btnW = (w - 18) / 3.0;

    _executeButton = [self createStyledButtonWithTitle:@"▶ Execute" frame:CGRectMake(0, h - barH, btnW, barH) primary:YES];
    [_executeButton addTarget:self action:@selector(onExecuteTapped) forControlEvents:UIControlEventTouchUpInside];
    [_editorTabContainer addSubview:_executeButton];

    _clearButton = [self createStyledButtonWithTitle:@"🗑 Clear" frame:CGRectMake(btnW + 9, h - barH, btnW, barH) primary:NO];
    [_clearButton addTarget:self action:@selector(onClearTapped) forControlEvents:UIControlEventTouchUpInside];
    [_editorTabContainer addSubview:_clearButton];

    _pasteButton = [self createStyledButtonWithTitle:@"📋 Paste" frame:CGRectMake((btnW + 9) * 2, h - barH, btnW, barH) primary:NO];
    [_pasteButton addTarget:self action:@selector(onPasteTapped) forControlEvents:UIControlEventTouchUpInside];
    [_editorTabContainer addSubview:_pasteButton];

    [_mainCard addSubview:_editorTabContainer];
}

- (void)setupScriptsTabWithFrame:(CGRect)frame {
    _scriptsTabContainer = [[UIView alloc] initWithFrame:frame];
    _scriptsTabContainer.hidden = YES;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:_scriptsTabContainer.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    NSArray *preloadedScripts = @[
        @{@"name": @"Infinite Yield", @"desc": @"Feature-packed administrative & fly script", @"src": @"loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()"},
        @{@"name": @"Dex Explorer iOS", @"desc": @"Inspect and view Roblox game hierarchy & CoreGui", @"src": @"loadstring(game:HttpGet('https://raw.githubusercontent.com/infyiff/backup/main/dex.lua'))()"},
        @{@"name": @"SimpleSpy V3", @"desc": @"Log and analyze RemoteEvents and RemoteFunctions", @"src": @"loadstring(game:HttpGet('https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua'))()"}
    ];

    CGFloat cardY = 0;
    for (NSDictionary *item in preloadedScripts) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, cardY, frame.size.width, 68)];
        card.backgroundColor = [UIColor colorWithRed:0.08 green:0.09 blue:0.15 alpha:0.75];
        card.layer.cornerRadius = 8.0;
        card.layer.borderColor = [UIColor colorWithRed:0.20 green:0.22 blue:0.32 alpha:0.5].CGColor;
        card.layer.borderWidth = 1.0;

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, frame.size.width - 110, 22)];
        nameLabel.text = item[@"name"];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        [card addSubview:nameLabel];

        UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 34, frame.size.width - 110, 20)];
        descLabel.text = item[@"desc"];
        descLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        descLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
        [card addSubview:descLabel];

        UIButton *runBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        runBtn.frame = CGRectMake(frame.size.width - 90, 16, 78, 36);
        runBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.18 blue:0.80 alpha:0.9];
        runBtn.layer.cornerRadius = 6.0;
        [runBtn setTitle:@"Run" forState:UIControlStateNormal];
        runBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        [runBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        NSString *srcCode = item[@"src"];
        [runBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [self logToConsole:[NSString stringWithFormat:@"Executing %@", item[@"name"]] isError:NO];
            Luxina::Core::ExecuteScript([srcCode UTF8String]);
        }] forControlEvents:UIControlEventTouchUpInside];

        [card addSubview:runBtn];
        [scrollView addSubview:card];
        cardY += 76;
    }

    scrollView.contentSize = CGSizeMake(frame.size.width, cardY);
    [_scriptsTabContainer addSubview:scrollView];
    [_mainCard addSubview:_scriptsTabContainer];
}

- (void)setupConsoleTabWithFrame:(CGRect)frame {
    _consoleTabContainer = [[UIView alloc] initWithFrame:frame];
    _consoleTabContainer.hidden = YES;

    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;

    _consoleTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, w, h - 44)];
    _consoleTextView.backgroundColor = [UIColor colorWithRed:0.02 green:0.03 blue:0.05 alpha:0.9];
    _consoleTextView.textColor = [UIColor colorWithRed:0.3 green:0.9 blue:0.4 alpha:1.0];
    _consoleTextView.font = [UIFont fontWithName:@"Menlo" size:11] ?: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    _consoleTextView.editable = NO;
    _consoleTextView.layer.cornerRadius = 8.0;
    _consoleTextView.text = @"[luxinaios] Console initialized. Ready for execution.\n";
    [_consoleTabContainer addSubview:_consoleTextView];

    _clearConsoleButton = [self createStyledButtonWithTitle:@"Clear Logs" frame:CGRectMake(0, h - 38, w, 36) primary:NO];
    [_clearConsoleButton addTarget:self action:@selector(onClearConsoleTapped) forControlEvents:UIControlEventTouchUpInside];
    [_consoleTabContainer addSubview:_clearConsoleButton];

    [_mainCard addSubview:_consoleTabContainer];
}

- (void)setupSettingsTabWithFrame:(CGRect)frame {
    _settingsTabContainer = [[UIView alloc] initWithFrame:frame];
    _settingsTabContainer.hidden = YES;

    UILabel *headerLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, frame.size.width - 16, 24)];
    headerLbl.text = @"Executor Settings";
    headerLbl.textColor = [UIColor whiteColor];
    headerLbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_settingsTabContainer addSubview:headerLbl];

    // FPS Unlocker row
    UILabel *fpsLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 44, 140, 28)];
    fpsLbl.text = @"Unlock 120 FPS";
    fpsLbl.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    fpsLbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [_settingsTabContainer addSubview:fpsLbl];

    UISwitch *fpsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(frame.size.width - 64, 42, 51, 31)];
    fpsSwitch.on = YES;
    [fpsSwitch addTarget:self action:@selector(onFpsToggled:) forControlEvents:UIControlEventValueChanged];
    [_settingsTabContainer addSubview:fpsSwitch];

    // Info Label
    UILabel *infoLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 100, frame.size.width - 16, 80)];
    infoLbl.numberOfLines = 0;
    infoLbl.text = @"luxinaios Engine v1.0.0\nTarget Build: 2.748.1526\nLuau VM: Elevated Security Level 8\nCapabilities: 0x3FFFFFFF";
    infoLbl.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    infoLbl.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    [_settingsTabContainer addSubview:infoLbl];

    [_mainCard addSubview:_settingsTabContainer];
}

- (UIButton *)createStyledButtonWithTitle:(NSString *)title frame:(CGRect)frame primary:(BOOL)primary {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.layer.cornerRadius = 8.0;
    btn.layer.masksToBounds = YES;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];

    if (primary) {
        btn.backgroundColor = [UIColor colorWithRed:0.35 green:0.20 blue:0.95 alpha:0.95];
        btn.layer.borderColor = [UIColor colorWithRed:0.5 green:0.35 blue:1.0 alpha:0.8].CGColor;
        btn.layer.borderWidth = 1.0;
    } else {
        btn.backgroundColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.22 alpha:0.85];
        btn.layer.borderColor = [UIColor colorWithRed:0.25 green:0.28 blue:0.40 alpha:0.6].CGColor;
        btn.layer.borderWidth = 1.0;
    }
    return btn;
}

- (void)tabChanged:(UISegmentedControl *)sender {
    NSInteger idx = sender.selectedSegmentIndex;
    _editorTabContainer.hidden = (idx != 0);
    _scriptsTabContainer.hidden = (idx != 1);
    _consoleTabContainer.hidden = (idx != 2);
    _settingsTabContainer.hidden = (idx != 3);
}

- (void)onExecuteTapped {
    NSString *source = _codeTextView.text;
    if (source.length == 0) return;

    [self logToConsole:@"[luxinaios] Running script..." isError:NO];
    Luxina::Core::ExecuteScript([source UTF8String]);
}

- (void)onClearTapped {
    _codeTextView.text = @"";
}

- (void)onPasteTapped {
    NSString *clip = [UIPasteboard generalPasteboard].string;
    if (clip.length > 0) {
        _codeTextView.text = clip;
    }
}

- (void)onClearConsoleTapped {
    _consoleTextView.text = @"";
}

- (void)onFpsToggled:(UISwitch *)sender {
    Luxina::Core::SetFPSCap(sender.isOn ? 120.0 : 60.0);
}

- (void)toggleVisibility {
    _isOpen = !_isOpen;
    if (_isOpen) {
        _mainCard.alpha = 0.0;
        _mainCard.transform = CGAffineTransformMakeScale(0.85, 0.85);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self->_mainCard.alpha = 1.0;
            self->_mainCard.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self->_mainCard.alpha = 0.0;
            self->_mainCard.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:nil];
    }
}

- (void)logToConsole:(NSString *)message isError:(BOOL)isError {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"HH:mm:ss"];
        NSString *ts = [df stringFromDate:[NSDate date]];
        NSString *line = [NSString stringWithFormat:@"[%@] %@\n", ts, message];
        self->_consoleTextView.text = [self->_consoleTextView.text stringByAppendingString:line];
        [self->_consoleTextView scrollRangeToVisible:NSMakeRange(self->_consoleTextView.text.length - 1, 1)];
    });
}

@end

// ============================================================================
// LuxinaUIManager Implementation
// ============================================================================
@implementation LuxinaUIManager {
    UIWindow *_overlayWindow;
    LuxinaExecutorViewController *_viewController;
    LuxinaFloatingButton *_floatingButton;
}

+ (instancetype)sharedInstance {
    static LuxinaUIManager *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[LuxinaUIManager alloc] init];
    });
    return sInstance;
}

- (void)initializeUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_overlayWindow) return;

        // Create overlay window above game alert level
        UIWindowScene *scene = nil;
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }

        if (scene) {
            self->_overlayWindow = [[UIWindow alloc] initWithWindowScene:scene];
        } else {
            self->_overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        self->_overlayWindow.windowLevel = UIWindowLevelAlert + 100.0;
        self->_overlayWindow.backgroundColor = [UIColor clearColor];
        self->_overlayWindow.hidden = NO;

        self->_viewController = [[LuxinaExecutorViewController alloc] init];
        self->_overlayWindow.rootViewController = self->_viewController;

        // Floating draggable button setup (Initial view)
        CGFloat btnSize = 54.0;
        CGFloat startX = [UIScreen mainScreen].bounds.size.width - btnSize - 16;
        CGFloat startY = [UIScreen mainScreen].bounds.size.height * 0.4;

        self->_floatingButton = [[LuxinaFloatingButton alloc] initWithFrame:CGRectMake(startX, startY, btnSize, btnSize)];
        self->_viewController.floatingButton = self->_floatingButton;

        __weak LuxinaUIManager *weakSelf = self;
        self->_floatingButton.onTapHandler = ^{
            LuxinaUIManager *strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf->_viewController toggleVisibility];
            }
        };

        [self->_overlayWindow addSubview:self->_floatingButton];
    });
}

- (void)appendLog:(const std::string&)text isError:(bool)isError {
    NSString *nsText = [NSString stringWithUTF8String:text.c_str()];
    [_viewController logToConsole:nsText isError:isError];
}

- (void)updateAttachmentStatus:(bool)attached {
    [_floatingButton updateStatus:attached];
}

@end

namespace Luxina::UI {
    void Initialize() {
        [[LuxinaUIManager sharedInstance] initializeUI];
    }
    void AppendLog(const std::string& text, bool isError) {
        [[LuxinaUIManager sharedInstance] appendLog:text isError:isError];
    }
    void UpdateAttachmentStatus(bool attached) {
        [[LuxinaUIManager sharedInstance] updateAttachmentStatus:attached];
    }
}

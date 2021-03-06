//
//  UINavigationController+SJVideoPlayerAdd.m
//  SJBackGR
//
//  Created by BlueDancer on 2017/9/26.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "UINavigationController+SJVideoPlayerAdd.h"
#import <objc/message.h>
#import "UIViewController+SJVideoPlayerAdd.h"
#import "SJScreenshotView.h"


#define SJ_Shift        (-[UIScreen mainScreen].bounds.size.width * 0.382)


#pragma mark - Timer


@interface NSTimer (SJVideoPlayerExtension)

+ (instancetype)SJVideoPlayer_scheduledTimerWithTimeInterval:(NSTimeInterval)ti exeBlock:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo;

@end


@implementation NSTimer (SJVideoPlayerExtension)

+ (instancetype)SJVideoPlayer_scheduledTimerWithTimeInterval:(NSTimeInterval)ti exeBlock:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo {
    NSAssert(block, @"block 不可为空");
    return [self scheduledTimerWithTimeInterval:ti target:self selector:@selector(SJVideoPlayer_exeTimerEvent:) userInfo:[block copy] repeats:yesOrNo];
}

+ (void)SJVideoPlayer_exeTimerEvent:(NSTimer *)timer {
    void(^block)(NSTimer *timer) = timer.userInfo;
    if ( block ) block(timer);
}

@end


#pragma mark -








#pragma mark -

static SJScreenshotView *SJVideoPlayer_screenshotView;
static NSMutableArray<UIImage *> * SJVideoPlayer_screenshotImagesM;



#pragma mark - UIViewController

@interface UIViewController (SJVideoPlayerExtension)

@property (class, nonatomic, strong, readonly) SJScreenshotView *SJVideoPlayer_screenshotView;
@property (class, nonatomic, strong, readonly) NSMutableArray<UIImage *> * SJVideoPlayer_screenshotImagesM;

@end

@implementation UIViewController (SJVideoPlayerExtension)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class vc = [self class];
        
        // dismiss
        Method dismissViewControllerAnimatedCompletion = class_getInstanceMethod(vc, @selector(dismissViewControllerAnimated:completion:));
        Method SJVideoPlayer_dismissViewControllerAnimatedCompletion = class_getInstanceMethod(vc, @selector(SJVideoPlayer_dismissViewControllerAnimated:completion:));
        
        method_exchangeImplementations(SJVideoPlayer_dismissViewControllerAnimatedCompletion, dismissViewControllerAnimatedCompletion);
    });
}

- (void)SJVideoPlayer_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if ( !self.navigationController ) {
        // call origin method
        [self SJVideoPlayer_dismissViewControllerAnimated:flag completion:completion];
        return;
    }
    
    // reset image
    if ( self.presentingViewController ) [self SJVideoPlayer_resetScreenshotImageForLastIndex:self.navigationController.childViewControllers.count];
    
    // call origin method
    [self SJVideoPlayer_dismissViewControllerAnimated:flag completion:completion];
}

+ (void)SJVideoPlayer_resetScreenshotImage {
    // remove last screenshot
    [[[self class] SJVideoPlayer_screenshotImagesM] removeLastObject];
    // update screenshotImage
    [[[self class] SJVideoPlayer_screenshotView] setImage:[[[self class] SJVideoPlayer_screenshotImagesM] lastObject]];
}

- (void)SJVideoPlayer_resetScreenshotImage {
    [[self class] SJVideoPlayer_resetScreenshotImage];
}

- (void)SJVideoPlayer_resetScreenshotImageForLastIndex:(NSInteger)lastIndex {
    if ( lastIndex <= 0 ) return;
    // remove last screenshot
    NSMutableArray *arrayM = [[self class] SJVideoPlayer_screenshotImagesM];
    [arrayM removeObjectsInRange:NSMakeRange(arrayM.count - lastIndex, lastIndex)];
    
    // update screenshotImage
    [[[self class] SJVideoPlayer_screenshotView] setImage:[[[self class] SJVideoPlayer_screenshotImagesM] lastObject]];
}

- (void)SJVideoPlayer_updateScreenshot {
    // get scrrenshort
    id appDelegate = [UIApplication sharedApplication].delegate;
    UIWindow *window = [appDelegate valueForKey:@"window"];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(window.frame.size.width, window.frame.size.height), YES, 0);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // add to container
    [[self class].SJVideoPlayer_screenshotImagesM addObject:viewImage];
    
    // change screenshotImage
    [[self class].SJVideoPlayer_screenshotView setImage:viewImage];
}

+ (SJScreenshotView *)SJVideoPlayer_screenshotView {
    if ( SJVideoPlayer_screenshotView ) return SJVideoPlayer_screenshotView;
    SJVideoPlayer_screenshotView = [SJScreenshotView new];
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat width = MIN(bounds.size.width, bounds.size.height);
    CGFloat height = MAX(bounds.size.width, bounds.size.height);
    SJVideoPlayer_screenshotView.frame = CGRectMake(0, 0, width, height);
    SJVideoPlayer_screenshotView.hidden = YES;
    return SJVideoPlayer_screenshotView;
}

+ (NSMutableArray<UIImage *> *)SJVideoPlayer_screenshotImagesM {
    if ( SJVideoPlayer_screenshotImagesM ) return SJVideoPlayer_screenshotImagesM;
    SJVideoPlayer_screenshotImagesM = [NSMutableArray array];
    return SJVideoPlayer_screenshotImagesM;
}

@end



#pragma mark - UINavigationController
@interface UINavigationController (SJVideoPlayerExtension)<UINavigationControllerDelegate>

@property (nonatomic, assign, readwrite) BOOL isObserver;

@end

@implementation UINavigationController (SJVideoPlayerExtension)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // App launching
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SJVideoPlayer_addscreenshotImageViewToWindow) name:UIApplicationDidFinishLaunchingNotification object:nil];
        
        Class nav = [self class];
        
        // Init
        Method initWithRootViewController = class_getInstanceMethod(nav, @selector(initWithRootViewController:));
        Method SJVideoPlayer_initWithRootViewController = class_getInstanceMethod(nav, @selector(SJVideoPlayer_initWithRootViewController:));
        method_exchangeImplementations(SJVideoPlayer_initWithRootViewController, initWithRootViewController);
        
        // Push
        Method pushViewControllerAnimated = class_getInstanceMethod(nav, @selector(pushViewController:animated:));
        Method SJVideoPlayer_pushViewControllerAnimated = class_getInstanceMethod(nav, @selector(SJVideoPlayer_pushViewController:animated:));
        method_exchangeImplementations(SJVideoPlayer_pushViewControllerAnimated, pushViewControllerAnimated);
        
        // Pop
        Method popViewControllerAnimated = class_getInstanceMethod(nav, @selector(popViewControllerAnimated:));
        Method SJVideoPlayer_popViewControllerAnimated = class_getInstanceMethod(nav, @selector(SJVideoPlayer_popViewControllerAnimated:));
        method_exchangeImplementations(popViewControllerAnimated, SJVideoPlayer_popViewControllerAnimated);
        
        // Pop Root VC
        Method popToRootViewControllerAnimated = class_getInstanceMethod(nav, @selector(popToRootViewControllerAnimated:));
        Method SJVideoPlayer_popToRootViewControllerAnimated = class_getInstanceMethod(nav, @selector(SJVideoPlayer_popToRootViewControllerAnimated:));
        method_exchangeImplementations(popToRootViewControllerAnimated, SJVideoPlayer_popToRootViewControllerAnimated);
        
        // Pop To View Controller
        Method popToViewControllerAnimated = class_getInstanceMethod(nav, @selector(popToViewController:animated:));
        Method SJVideoPlayer_popToViewControllerAnimated = class_getInstanceMethod(nav, @selector(SJVideoPlayer_popToViewController:animated:));
        method_exchangeImplementations(popToViewControllerAnimated, SJVideoPlayer_popToViewControllerAnimated);
    });
}

- (void)dealloc {
    if ( self.isObserver ) [self.interactivePopGestureRecognizer removeObserver:self forKeyPath:@"state"];
}

- (void)setIsObserver:(BOOL)isObserver {
    objc_setAssociatedObject(self, @selector(isObserver), @(isObserver), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isObserver {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

// App launching
+ (void)SJVideoPlayer_addscreenshotImageViewToWindow {
    UIWindow *window = [(id)[UIApplication sharedApplication].delegate valueForKey:@"window"];
    NSAssert(window, @"Window was not found and cannot continue!");
    [window insertSubview:self.SJVideoPlayer_screenshotView atIndex:0];
}

// Init
- (instancetype)SJVideoPlayer_initWithRootViewController:(UIViewController *)rootViewController {
    __weak typeof(rootViewController) _rootViewController = rootViewController;
    [[NSTimer SJVideoPlayer_scheduledTimerWithTimeInterval:0.05 exeBlock:^(NSTimer *timer) {
        if ( !_rootViewController ) { [timer invalidate]; return ; }
        if ( !_rootViewController.navigationController ) return;
        
        // timer invalidate
        [timer invalidate];
        
        // get nav
        UINavigationController *nav = _rootViewController.navigationController;
        [nav.interactivePopGestureRecognizer addObserver:nav forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
        nav.isObserver = YES;
        
        // use custom gesture
        nav.useNativeGesture = NO;
        
        // border shadow
        nav.view.layer.shadowOffset = CGSizeMake(-1, 0);
        nav.view.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
        nav.view.layer.shadowRadius = 1;
        nav.view.layer.shadowOpacity = 1;
        
        // delegate
        nav.delegate = (id)[UINavigationController class];
        
    } repeats:YES] fire];
    return [self SJVideoPlayer_initWithRootViewController:rootViewController];
}


// Push
static UINavigationControllerOperation _navOperation;
- (void)SJVideoPlayer_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    _navOperation = UINavigationControllerOperationPush;
    // push update screenshot
    [self SJVideoPlayer_updateScreenshot];
    // call origin method
    [self SJVideoPlayer_pushViewController:viewController animated:animated];
}

// Pop
- (UIViewController *)SJVideoPlayer_popViewControllerAnimated:(BOOL)animated {
    _navOperation = UINavigationControllerOperationPop;
    // call origin method
    return [self SJVideoPlayer_popViewControllerAnimated:animated];
}

// Pop To RootView Controller
- (NSArray<UIViewController *> *)SJVideoPlayer_popToRootViewControllerAnimated:(BOOL)animated {
    [self SJVideoPlayer_resetScreenshotImageForLastIndex:self.childViewControllers.count - 1];
    return [self SJVideoPlayer_popToRootViewControllerAnimated:animated];
}

// Pop To View Controller
- (NSArray<UIViewController *> *)SJVideoPlayer_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.childViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( viewController != obj ) return;
        *stop = YES;
        [self SJVideoPlayer_resetScreenshotImageForLastIndex:self.childViewControllers.count - idx - 1];
    }];
    return [self SJVideoPlayer_popToViewController:viewController animated:animated];
}

// navController delegate
static __weak UIViewController *_tmpShowViewController;
+ (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ( _navOperation == UINavigationControllerOperationPush ) { return;}
    _tmpShowViewController = viewController;
}

+ (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ( _navOperation != UINavigationControllerOperationPop ) return;
    if ( _tmpShowViewController != viewController ) return;
    
    // reset
    [self SJVideoPlayer_resetScreenshotImage];
    _tmpShowViewController = nil;
    _navOperation = UINavigationControllerOperationNone;
}

// observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(UIScreenEdgePanGestureRecognizer *)gesture change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    switch ( gesture.state ) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            break;
        default: {
            // update
            self.useNativeGesture = self.useNativeGesture;
        }
            break;
    }
}

@end






#pragma mark - Gesture
@implementation UINavigationController (SJVideoPlayerAdd)

- (UIPanGestureRecognizer *)sj_pan {
    UIPanGestureRecognizer *sj_pan = objc_getAssociatedObject(self, _cmd);
    if ( sj_pan ) return sj_pan;
    sj_pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(SJVideoPlayer_handlePanGR:)];
    [self.view addGestureRecognizer:sj_pan];
    sj_pan.delegate = self;
    objc_setAssociatedObject(self, _cmd, sj_pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return sj_pan;
}


- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translate = [gestureRecognizer translationInView:self.view];
    BOOL possible = translate.x > 0 && translate.y == 0;
    if ( possible ) return YES;
    else return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ( [otherGestureRecognizer isMemberOfClass:NSClassFromString(@"UIPanGestureRecognizer")] ) {
        return NO;
    }
    
    if ([otherGestureRecognizer isMemberOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")] ||
        [otherGestureRecognizer isMemberOfClass:NSClassFromString(@"UIScrollViewPagingSwipeGestureRecognizer")]) {
        if ( [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] ) {
            return [self SJVideoPlayer_considerScrollView:(UIScrollView *)otherGestureRecognizer.view otherGestureRecognizer:otherGestureRecognizer];
        }
    }
    return YES;
}


- (BOOL)SJVideoPlayer_considerScrollView:(UIScrollView *)subScrollView otherGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ( 0 != subScrollView.contentOffset.x ) return NO;
    UIView *sup = subScrollView.superview;
    // 用于判断横向移动的方向 (向左还是向右)
    CGPoint translate = [self.sj_pan translationInView:self.view];
    // 尽量考虑 scrollView 嵌套在 scrollView 的情况. (只向上找了5层)
    for ( int i = 0 ; i < 5; ++ i ) {
        if ( [sup isKindOfClass:[UIScrollView class]] ) {
            // 如果 scrollView 从未移动过
            if ( 0 == subScrollView.contentOffset.x ) {
                // 横向 向右滑的情况
                if ( translate.x > 0 ) {
                    // 取消 subScrollView 滑动
                    [otherGestureRecognizer setValue:@(UIGestureRecognizerStateCancelled) forKey:@"state"];
                    // 全屏手势 处理
                    return YES;
                }
                // 横向 向左滑动的情况
                else {
                    // 全屏手势 不处理
                    return NO;
                }
            }
            // 如果 subScrollView 没有复位(即 contentOffset.x != 0 ), 则不触发全局手势
            else return NO;
        }
        sup = sup.superview;
    }
    // 如果不嵌套并且向左滑动
    if ( translate.x <= 0 ) return NO;
    return YES;
}

- (void)SJVideoPlayer_handlePanGR:(UIPanGestureRecognizer *)pan {
    if ( self.childViewControllers.count <= 1 ) return;
    
    CGFloat offset = [pan translationInView:self.view].x;
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            [self SJVideoPlayer_ViewWillBeginDragging];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            // 如果从右往左滑
            if ( offset < 0 ) return;
            [self SJVideoPlayer_ViewDidDrag:offset];
        }
            break;
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self SJVideoPlayer_ViewDidEndDragging:offset];
        }
            break;
    }
}

- (void)SJVideoPlayer_ViewWillBeginDragging {
    [self.view endEditing:YES];
    
    [[self class] SJVideoPlayer_screenshotView].hidden = NO;
    
    // call block
    if ( self.topViewController.sj_viewWillBeginDragging ) self.topViewController.sj_viewWillBeginDragging(self.topViewController);
    
    
    // begin animation
    [[self class] SJVideoPlayer_screenshotView].transform = CGAffineTransformMakeTranslation(SJ_Shift, 0);
}

- (void)SJVideoPlayer_ViewDidDrag:(CGFloat)offset {
    self.view.transform = CGAffineTransformMakeTranslation(offset, 0);
    
    // call block
    if ( self.topViewController.sj_viewDidDrag ) self.topViewController.sj_viewDidDrag(self.topViewController);
    
    // continuous animation
    CGFloat rate = offset / self.view.frame.size.width;
    [[self class] SJVideoPlayer_screenshotView].transform = CGAffineTransformMakeTranslation(SJ_Shift - SJ_Shift * rate, 0);
    [[[self class] SJVideoPlayer_screenshotView] setShadeAlpha:1 - rate];
}

- (void)SJVideoPlayer_ViewDidEndDragging:(CGFloat)offset {
    CGFloat rate = offset / self.view.frame.size.width;
    if ( rate < self.scMaxOffset ) {
        [UIView animateWithDuration:0.25 animations:^{
            self.view.transform = CGAffineTransformIdentity;
            
            // reset status
            [[self class] SJVideoPlayer_screenshotView].transform = CGAffineTransformMakeTranslation(SJ_Shift, 0);
            [[[self class] SJVideoPlayer_screenshotView] setShadeAlpha:1];
        } completion:^(BOOL finished) {
            [[self class] SJVideoPlayer_screenshotView].hidden = YES;
        }];
    }
    else {
        [UIView animateWithDuration:0.25 animations:^{
            self.view.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
            
            // finished animation
            [[self class] SJVideoPlayer_screenshotView].transform = CGAffineTransformMakeTranslation(0, 0);
            [[[self class] SJVideoPlayer_screenshotView] setShadeAlpha:0.001];
        } completion:^(BOOL finished) {
            [self popViewControllerAnimated:NO];
            self.view.transform = CGAffineTransformIdentity;
            [[self class] SJVideoPlayer_screenshotView].hidden = YES;
        }];
    }
    
    // call block
    if ( self.topViewController.sj_viewDidEndDragging ) self.topViewController.sj_viewDidEndDragging(self.topViewController);
    
}

@end







#pragma mark - Settings

@implementation UINavigationController (Settings)

- (void)setScMaxOffset:(float)scMaxOffset {
    objc_setAssociatedObject(self, @selector(scMaxOffset), @(scMaxOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (float)scMaxOffset {
    float offset = [objc_getAssociatedObject(self, _cmd) floatValue];
    if ( 0 == offset ) return 0.35;
    return offset;
}

- (void)setUseNativeGesture:(BOOL)useNativeGesture {
    objc_setAssociatedObject(self, @selector(useNativeGesture), @(useNativeGesture), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    switch (self.interactivePopGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:  break;
        default: {
            self.interactivePopGestureRecognizer.enabled = useNativeGesture;
            self.sj_pan.enabled = !useNativeGesture;
        }
            break;
    }
}

- (BOOL)useNativeGesture {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

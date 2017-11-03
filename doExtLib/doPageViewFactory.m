//
//  doPageViewFactory.m
//  doDebuger
//
//  Created by 刘吟 on 14/12/7.
//  Copyright (c) 2014年 deviceone. All rights reserved.
//

#import "doPageViewFactory.h"
#import "doPageView.h"
#import "doUIModuleHelper.h"
#import "doModule.h"
#import "doIPageView.h"
#import "doILogEngine.h"
#import "doServiceContainer.h"
#import "doTransition.h"
#import "doJsonHelper.h"
#import "doIScriptEngine.h"

#define KEYWINDOW [UIApplication sharedApplication].keyWindow
#define ANIMATION_DURATION .3

@interface doPageViewFactory()<UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
//@property (strong, nonatomic) UIScreenEdgePanGestureRecognizer *edgePanGesture;
@end

@implementation doPageViewFactory
{
    NSString *openPageAnimation;
    UIPanGestureRecognizer *_panGesture;
    BOOL _isInteractive;
    
    doPageView *_interativePage;
    
    BOOL isInteraction;
    
    NSString *dir;
    
    NSArray *_vcs;
}
#pragma mark -
#pragma mark -override
- (void) OpenPage: (NSString*) _appID : (NSString*) _uiPath : (NSString*) _scriptType :  (NSString*) _animationType : (NSString*)_data : (NSString*)_statusBarState  : (NSString*)_keyboardMode :(NSString*) _callbackName :(NSString*)_statusBarFgColor :(NSString *)_pageId :(NSString *)statusBarBgColor
{
    @try {
        UIViewController* current = [[doPageView alloc]init:_appID :_uiPath:_scriptType:_animationType:_data:_statusBarState:_keyboardMode :_statusBarFgColor :_pageId :statusBarBgColor];
        ((doPageView *)current).openPageAnimation = _animationType;
        openPageAnimation = _animationType;
        [self pushViewController:current animated:YES];
    }
    @catch (NSException *exception) {
        [doUIModuleHelper Alert:@"错误" msg: exception.reason];
    }
}
- (void) ClosePage:(NSString*) _animationType :(int)_layers :(NSString*) _data :(BOOL)_isPanClose
{
    if (_layers == 0) {
        return;
    }
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    id<doIPageView> pageview = [self.viewControllers lastObject];
    [self getAnimationType:_animationType];
    if (!_isPanClose) {
        NSUInteger poptoIndex = 0;
        if (_layers == 1) {
            poptoIndex = self.viewControllers.count-2;
        }else
            poptoIndex = self.viewControllers.count-_layers-1;
        
        pageview = [self.viewControllers objectAtIndex:poptoIndex];
        
        _vcs = [NSArray array];
        _vcs = [self popToViewController:(UIViewController *)pageview animated:YES];
    }else{
        doPageView *page = (doPageView *)self.topViewController;
        if (![page respondsToSelector:@selector(supportCloseParms)]) {
            [self DisposePanPage];
            return;
        }
        
        NSArray *parms = _interativePage.supportCloseParms;
        if (!parms) {
            [self DisposePanPage];
            return;
        }
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        _data = [doJsonHelper GetOneText:_dictParas :@"data" :@""];
        
        [self DisposePanPage];
    }
    
    if(![self.topViewController conformsToProtocol:@protocol(doIPageView) ])
        return;
    id<doIPageView> top = (id<doIPageView>)self.topViewController;
    doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
    [_result SetResultText:_data];
    if ([self.topViewController isKindOfClass:[doPageView class]]) {
        [((doModule*)top.PageModel).EventCenter FireEvent:@"result" :_result];
    }
    
}
- (void) ClosePage:(NSString*) _animationType :(int)_layers :(NSString*) _data
{
    if (self.viewControllers.count == 1) {
        return;
    }
    id<doIPageView> pageview = [self.viewControllers lastObject];
    if (!pageview) {
        return;
    }
    if (![[self.viewControllers lastObject] respondsToSelector:@selector(DisposeView)]) {
        return;
    }
    [self ClosePage:_animationType :_layers :_data :NO];
}

- (void)ClosePageToID:(NSString *)_animationType :(NSString *)_pageId :(NSString *)_data
{
    int _layers=1;
    NSArray *vcs = self.viewControllers;
    if (vcs.count<=1) {
        _layers=0;
    }else{
        if (!_pageId || [_pageId isEqualToString:@""]) {
            _layers = 1;
        }else{
            _layers = -1;
            vcs = [[vcs reverseObjectEnumerator] allObjects];
            for (NSUInteger i=0;i<vcs.count;i++) {
                doPageView *page = (doPageView *)[vcs objectAtIndex:i];
                if ([page respondsToSelector:@selector(pageId)]) {
                    if ([page.pageId isEqualToString:_pageId]) {
                        _layers = (int)i;
                        break;
                    }
                }
            }
        }
    }
    if (_layers == -1) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : @"id不存在"];
    }else
        [self ClosePage:_animationType :_layers :_data :NO];
}

#pragma mark -uiviewcontroller
-(BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}
#pragma mark -private
- (void)viewDidLoad
{
    self.delegate = self;
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPage:)];
    
//    _edgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(panPage:)];
//    _edgePanGesture.edges = UIRectEdgeLeft;
    
}

- (void)panPage:(UIPanGestureRecognizer *)pan {
    UIView *view = self.view;
    CGPoint p = [pan translationInView:view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
    }
    else if (pan.state == UIGestureRecognizerStateChanged) {
        if (!isInteraction) {
            isInteraction = YES;
            [self getAnimationType:@""];
            CGPoint location = [pan locationInView:view];
            if (self.viewControllers.count > 1) {
                if ([self validatePanDirection:view :p :location]) {
                    [[UIApplication sharedApplication].keyWindow endEditing:YES];
                    self.interactionController = [UIPercentDrivenInteractiveTransition new];
                    _interativePage = (doPageView *)[self popViewControllerAnimated:YES];
                }
            }
        }
        
        CGPoint translation = [pan translationInView:view];
        
        CGFloat progress = 0;
        if ([dir rangeOfString:@"l2r"].length > 0) {
            if (translation.x<0) {
                return;
            }
            progress = fabs(translation.x / CGRectGetWidth(view.bounds));
        }else if ([dir rangeOfString:@"r2l"].length > 0){
            if (translation.x>0) {
                return;
            }
            progress = fabs(translation.x / CGRectGetWidth(view.bounds));
        }else if ([dir rangeOfString:@"t2b"].length > 0){
            if (translation.y<0) {
                return;
            }
            progress = fabs(translation.y / CGRectGetHeight(view.bounds));
        }else if ([dir rangeOfString:@"b2t"].length > 0){
            if (translation.y>0) {
                return;
            }
            progress = fabs(translation.y / CGRectGetHeight(view.bounds));
        }
        NSLog(@"progress : %f",progress);
        [self.interactionController updateInteractiveTransition:progress];
    }
    else if (pan.state == UIGestureRecognizerStateEnded) {
        isInteraction = NO;
        if(self.interactionController.percentComplete > .5){
            [self ClosePage:@"" :1 :@"" :YES];
        }
        else { //取消拖动
            _interativePage = nil;
            [self.interactionController cancelInteractiveTransition];
        }
        self.interactionController = nil;
    }
}

- (BOOL)validatePanDirection:(UIView *)v :(CGPoint)panPoint :(CGPoint)locationPoint
{
    dir = openPageAnimation;
    if (isInteraction) {
        dir = [self getCloseAnimationDirection];
    }
    if ([dir rangeOfString:@"b2t"].length > 0) {
        if (panPoint.y<0) {
            if (locationPoint.y < CGRectGetMidY(v.bounds)) {
                return YES;
            }
        }else
            return NO;
    }else if ([dir rangeOfString:@"t2b"].length > 0) {
        if (panPoint.y>0) {
            if (locationPoint.y < CGRectGetMidY(v.bounds)) {
                return YES;
            }
        }else
            return NO;
    }else if ([dir rangeOfString:@"l2r"].length > 0) {
        if (panPoint.x>0) {
            if (locationPoint.x < CGRectGetMidX(v.bounds)) {
                return YES;
            }
        }else
            return NO;
    }else if ([dir rangeOfString:@"r2l"].length > 0) {
        if (panPoint.x<0) {
            if (locationPoint.x < CGRectGetMidX(v.bounds)) {
                return YES;
            }
        }else
            return NO;
    }
    return YES;
}

- (NSString *)getCloseAnimationDirection
{
    if ([openPageAnimation rangeOfString:@"b2t"].length > 0) {
        dir = @"t2b";
    }else if ([openPageAnimation rangeOfString:@"t2b"].length > 0) {
        dir = @"b2t";
    }else if ([openPageAnimation rangeOfString:@"l2r"].length > 0) {
        dir = @"r2l";
    }else if ([openPageAnimation rangeOfString:@"r2l"].length > 0) {
        dir = @"l2r";
    }else if ([openPageAnimation rangeOfString:@"page_curl"].length > 0) {
        dir = @"b2t";
    }else if ([openPageAnimation rangeOfString:@"page_uncurl"].length > 0) {
        dir = @"t2b";
    }else
        dir = @"l2r";
    return dir;
}

- (void)getAnimationType:(NSString *)_animationType
{
    id<doIPageView> pageview = [self.viewControllers lastObject];
    if ([[self.viewControllers lastObject] respondsToSelector:@selector(openPageAnimation)]) {
        if(_animationType==nil||_animationType.length<=0)
            _animationType = [doUIModuleHelper GetCloseAnimation:pageview.openPageAnimation];
        if (isInteraction) {
            _animationType = pageview.openPageAnimation;
        }
        openPageAnimation = _animationType;
    }
}


- (void)DisposePanPage
{
    [_interativePage DisposeView];
    _interativePage = nil;
    [self.interactionController finishInteractiveTransition];
}

-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    
    doTransition *animationController = [doTransition new];
    AnimationType type;
    
    if (operation == UINavigationControllerOperationPush) {
        type = AnimationTypePresent;
    }else
        type = AnimationTypeDismiss;
    
    doPageView *fromPage = (doPageView *)fromVC;
    doPageView *toPage = (doPageView *)toVC;
    
    if ([fromPage respondsToSelector:@selector(operation)]) {
        fromPage.operation = operation;
    }
    if ([toPage respondsToSelector:@selector(operation)]) {
        toPage.operation = operation;
    }
    
    if (![fromPage isKindOfClass:[doPageView class]] && ![toPage isKindOfClass:[doPageView class]]) { // 三方界面中跳转
        if (operation == UINavigationControllerOperationPush) { // push
            return [animationController getTransitionAnimation:openPageAnimation :ANIMATION_DURATION :type :NO];
        }
        if (operation == UINavigationControllerOperationPop) { // pop
            return [animationController getTransitionAnimation:[self getTheOppositeAnimationOfOpenPageAnimation:openPageAnimation] :ANIMATION_DURATION :type :NO];
        }
    }
    
    if (![fromPage isKindOfClass:[doPageView class]]) {
        if (operation == UINavigationControllerOperationPop) { // 从三方页面pop到pageView
            return [animationController getTransitionAnimation:[self getTheOppositeAnimationOfOpenPageAnimation:openPageAnimation] :ANIMATION_DURATION :type :NO];
        }
    }
    
    if (![toPage isKindOfClass:[doPageView class]]) {
        if (operation == UINavigationControllerOperationPush) { // 从pageView push到三方界面
            return [animationController getTransitionAnimation:openPageAnimation :ANIMATION_DURATION :type :NO];
        }
    }
    
    return [animationController getTransitionAnimation:openPageAnimation :ANIMATION_DURATION :type :isInteraction];
}

- (NSString*)getTheOppositeAnimationOfOpenPageAnimation:(NSString*)pageAnimation {
    NSString *oppositePageAnimation;
    if([pageAnimation isEqualToString:@"slide_l2r"]) {
        oppositePageAnimation = @"slide_r2l";
    }else if ([pageAnimation isEqualToString:@"slide_r2l"]) {
        oppositePageAnimation = @"slide_l2r";
    }else if ([pageAnimation isEqualToString:@"slide_b2t"]) {
        oppositePageAnimation = @"slide_t2b";
    }else if ([pageAnimation isEqualToString:@"slide_t2b"]) {
        oppositePageAnimation = @"slide_b2t";
    }else if ([pageAnimation isEqualToString:@"push_l2r"]) {
        oppositePageAnimation = @"push_r2l";
    }else if ([pageAnimation isEqualToString:@"push_r2l"]) {
        oppositePageAnimation = @"push_l2r";
    }else if ([pageAnimation isEqualToString:@"push_b2t"]) {
        oppositePageAnimation = @"push_t2b";
    }else if ([pageAnimation isEqualToString:@"push_t2b"]) {
        oppositePageAnimation = @"push_b2t";
    }else if ([pageAnimation isEqualToString:@"fade"]) {
        oppositePageAnimation = @"fade";
    }else if ([pageAnimation isEqualToString:@"page_curl"]) {
        oppositePageAnimation = @"page_uncurl";
    }else if ([pageAnimation isEqualToString:@"page_uncurl"]) {
        oppositePageAnimation = @"page_curl";
    }else if ([pageAnimation isEqualToString:@"cube"]) {
        oppositePageAnimation = @"cube";
    }else if ([pageAnimation isEqualToString:@"slide_l2r_1"]) {
        oppositePageAnimation = @"slide_r2l_1";
    }else if ([pageAnimation isEqualToString:@"slide_r2l_1"]) {
        oppositePageAnimation = @"slide_l2r_1";
    }else if ([pageAnimation isEqualToString:@"push_l2r_1"]) {
        oppositePageAnimation = @"push_r2l_1";
    }else if ([pageAnimation isEqualToString:@"push_r2l_1"]) {
        oppositePageAnimation = @"push_l2r_1";
    }
    return oppositePageAnimation;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return self.interactionController;
}


- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [_vcs makeObjectsPerformSelector:@selector(DisposeView)];
    _vcs = nil;
    doPageView *page = (doPageView *)viewController;
    isInteraction = NO;
    if ([page respondsToSelector:@selector(supportCloseParms)]) {
        NSArray *parms = page.supportCloseParms;
        if (!parms) {
            [page.view removeGestureRecognizer:_panGesture];
            return;
        }
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        BOOL support = [doJsonHelper GetOneBoolean:_dictParas :@"support" :YES];
        if (!support) {
            [page.view removeGestureRecognizer:_panGesture];
            return;
        }
        [page.view addGestureRecognizer:_panGesture];
//        [page.view addGestureRecognizer:_edgePanGesture];
    }else
        [page.view removeGestureRecognizer:_panGesture];
}

@end


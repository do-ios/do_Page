//
//  doPageView.m
//  doDebuger
//
//  Created by 刘吟 on 14/12/9.
//  Copyright (c) 2014年 deviceone. All rights reserved.
//

#import "doPageView.h"
#import "doServiceContainer.h"
#import "doIApp.h"
#import "doIGlobal.h"
#import "doISourceFS.h"
#import "doIPageFactory.h"
#import "doUIContainer.h"
#import "do_Page_SM.h"
#import "doDefines.h"
#import "doUIModuleHelper.h"
#import "doBaseAppDelegate.h"
#import "doDefines.h"
#import "doIAppSecurity.h"

@implementation doPageView
{
@private
    BOOL hasLoaded;
    NSString *keyboardMode;
}
@synthesize PageModel = _PageModel;
@synthesize CustomScriptType = _CustomScriptType;
@synthesize statusBarState = _statusBarState;
@synthesize statusBarFgColor = _statusBarFgColor;
@synthesize pageId = _pageId;
@synthesize openPageAnimation = _openPageAnimation;
@synthesize supportCloseParms = _supportCloseParms;
@synthesize operation = _operation;
@synthesize statusBarBgColor = _statusBarBgColor;

#pragma mark -init
-(id)init:(NSString *) _appID : (NSString *) _uiPath : (NSString *) _scriptType :(NSString *) _animationType :(NSString *) _data : (NSString *) _statusState :(NSString *) _keyboardMode :(NSString*)fgColor :(NSString *)Id :(NSString *)statusBarBgColor
{
    self = [super init];
    if(self)
    {
        self.view.backgroundColor = [UIColor whiteColor];
        hasLoaded = NO;
        id<doIApp> _app = [[doServiceContainer Instance].Global  GetAppByID:_appID];
        if(_app == nil)
        {
            [NSException raise:@"PageView" format:@"无效的应用ID:%@",_appID,nil];
        }

        doSourceFile *_uiFile = [_app.SourceFS GetSourceByFileName:[self getRealFileName:_uiPath]];
        BOOL isAdapterUiFile = YES;
        if(_uiFile == nil)
        {
            isAdapterUiFile = NO;
            _uiFile = [_app.SourceFS GetSourceByFileName:_uiPath];
            if (!_uiFile) {
                [NSException raise:@"PageView" format:@"试图打开一个无效的页面文件:%@",_uiPath,nil];
            }
        }
        _CustomScriptType = _scriptType;
        _statusBarState = _statusState;
        _statusBarFgColor = fgColor;
        _statusBarBgColor = statusBarBgColor;
        _pageId = Id;
        keyboardMode = _keyboardMode;
        @try {
            _PageModel = [[doServiceContainer Instance].PageFactory CreatePage : _app : self : _uiFile];
            if (isAdapterUiFile) {
                int resolutionH = (int)[UIScreen mainScreen].scale * (int)[UIScreen mainScreen].bounds.size.width;
                int resolutionV = (int)[UIScreen mainScreen].scale * (int)[UIScreen mainScreen].bounds.size.height;
                [_PageModel setDesignScreenResolution:resolutionH :resolutionV];
            }else
                [_PageModel setDesignScreenResolution:[doServiceContainer Instance].Global.DesignScreenWidth :[doServiceContainer Instance].Global.DesignScreenHeight];

            _PageModel.SoftMode = _keyboardMode;
            //先显示页面activity视图，然后再装载里面的页面内容
            _PageModel.Data = _data;
            [_PageModel setStatusBarState:_statusBarState];
            [_PageModel LoadRootUiContainer];
            [self addStatusBar];
            
            //设置rootView
            doUIModule *rootModule = (doUIModule*)_PageModel.RootView;
            UIView* _rview =(UIView *)rootModule.CurrentUIModuleView;
            if (_rview != nil)
            {
                [self.view addSubview: _rview];
                //ios 7 下横屏bug
                if([_PageModel.statusBarState isEqualToString:@"show"])
                {
                    CGFloat y = [[rootModule GetPropertyValue:@"y"] floatValue]+statusBarHeight/rootModule.YZoom;
                    [rootModule SetPropertyValue:@"y" :[@(y) stringValue]];
                    [_rview setFrame:CGRectMake(_rview.frame.origin.x, _rview.frame.origin.y + statusBarHeight, _rview.frame.size.width, _rview.frame.size.height)];//如果不是全屏，页面整体下移20
                }
            }
            //构建脚本引擎的环境
            [_PageModel LoadScriptEngine:_uiPath :_uiFile.FileFullName];
            
            doUIModule *rootMoudle = self.PageModel.RootView;
            [rootMoudle DidLoadView];
        }
        @catch (NSException *exception) {
            @throw exception;
        }
    }
    
    return self;
}

- (UIView *)findResponder:(UIView *)v
{
    UIView *reponseV = nil;
    if (v.subviews.count == 0) {
        reponseV = nil;
    }
    for (UIView *tmp in v.subviews) {
        if(tmp.hidden){
            continue;
        }
        if ([tmp canBecomeFirstResponder] && !tmp.isFirstResponder && tmp.userInteractionEnabled) {
            reponseV = tmp;
            break;
        }else{
            reponseV = [self findResponder:tmp];
            if (reponseV) {
                break;
            }
        }
    }
    return reponseV;
}
#pragma mark -override

- (void) DisposeView
{
    [self.PageModel Dispose];
    _PageModel = nil;
}
#pragma mark -private
- (void) addStatusBar
{
    //如果不是全屏幕的话，加一个20高度的bar
    if([_PageModel.statusBarState isEqualToString:@"show"]||[_PageModel.statusBarState isEqualToString:@"transparent"]){
        
        [UIApplication sharedApplication].statusBarHidden = NO;
        UIView* _stausBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, statusBarHeight)];
        //屏幕旋转对状态栏影响
        id<doIAppSecurity> appModel = [doServiceContainer Instance].AppSecurity;
        NSString *orientation = appModel.appVersion;
        CGFloat max = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        if ([orientation isEqualToString:@"debug"]) {
            BOOL isLandscape = [doUIModuleHelper IsLandscape];
            if (isLandscape) {
                _stausBarView.frame = CGRectMake(0, 0, max, statusBarHeight);
            }
        }
        else
        {
            NSDictionary * dict = [[NSBundle mainBundle] infoDictionary];
            NSArray *arra = [dict objectForKey:@"UISupportedInterfaceOrientations"];
            NSString *interfaceStr = [arra objectAtIndex:0];
            if ([interfaceStr isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]||[interfaceStr isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) {
                _stausBarView.frame = CGRectMake(0, 0, max, statusBarHeight);
            }
        }
        UIColor *defaultColor = [doUIModuleHelper GetColorFromString:@"000000FF" : [UIColor clearColor]];
        _stausBarView.backgroundColor = [doUIModuleHelper GetColorFromString:_statusBarBgColor : defaultColor];
        [self.view addSubview: _stausBarView];
    }
}
#pragma mark -uiviewcontroller
//设置前景色
- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (!_statusBarFgColor || [_statusBarFgColor isEqualToString:@""]) {
        _statusBarFgColor = @"white";
    }
    UIStatusBarStyle style = ([_statusBarFgColor isEqualToString:@"black"])?UIStatusBarStyleDefault:UIStatusBarStyleLightContent;
    return style;
}

- (BOOL)prefersStatusBarHidden{
    if ([_PageModel.statusBarState isEqualToString:@"transparent"]){
        return NO;
    }else if ([_PageModel.statusBarState isEqualToString:@"hide"])
        return YES;
    return NO;
}

- (void)applyStatusBarStyleWhenStatusBarAppearanceSettingIsNO {
    if (!_statusBarFgColor || [_statusBarFgColor isEqualToString:@""]) {
        _statusBarFgColor = @"white";
    }
    UIStatusBarStyle style = ([_statusBarFgColor isEqualToString:@"black"])?UIStatusBarStyleDefault:UIStatusBarStyleLightContent;
    [UIApplication sharedApplication].statusBarStyle = style;
    
    if ([_PageModel.statusBarState isEqualToString:@"transparent"]){
        [UIApplication sharedApplication].statusBarHidden = false;
    }else if ([_PageModel.statusBarState isEqualToString:@"hide"]) {
        [UIApplication sharedApplication].statusBarHidden = true;
    }else { // show
        [UIApplication sharedApplication].statusBarHidden = false;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSNumber *vcBasseStatuesAppearace = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (!vcBasseStatuesAppearace.boolValue) { // 当前page已无效
        [self applyStatusBarStyleWhenStatusBarAppearanceSettingIsNO];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    doModule* _page = (doModule*)self.PageModel;
    if(!hasLoaded){
        UIView* _rview =(UIView *)((doUIModule*)self.PageModel.RootView).CurrentUIModuleView;
        if([keyboardMode isEqualToString:@"visible"])
        {
            UIView *v = [self findResponder:_rview];
            if (v) {
                [v becomeFirstResponder];
            }
        }
        [_page.EventCenter FireEvent:@"loaded" :nil];
        hasLoaded = YES;
    }
    [_page.EventCenter FireEvent:@"resume" :nil];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_operation == UINavigationControllerOperationPop) {
        doModule* _page = (doModule*)self.PageModel;
        [_page.EventCenter FireEvent:@"pause" :nil];
    }
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    doModule* _page = (doModule*)self.PageModel;
    [_page.EventCenter FireEvent:@"pause" :nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)shouldAutorotate
{
    return YES;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    doBaseAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if ([appDelegate.AppSecurityInfo.appVersion isEqualToString:@"debug"]) {
        BOOL isLandscape = [doUIModuleHelper IsLandscape];
        if (isLandscape) {
            return UIInterfaceOrientationMaskLandscape;
        }
        else
        {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
    else
    {
        NSDictionary * dict = [[NSBundle mainBundle] infoDictionary];
        NSArray *arra = [dict objectForKey:@"UISupportedInterfaceOrientations"];
        NSString *orientation = [arra objectAtIndex:0];
        if ([orientation isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]||[orientation isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) {
            return UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
        }
        else
        {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
}

- (void) dealloc
{
    NSLog(@"doPageView dealloc ..............");
}

- (NSString *)getRealFileName:(NSString *)uiFullName
{
    NSRange range = [uiFullName rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *path = [uiFullName substringToIndex:range.location];
    NSString *name = [uiFullName substringFromIndex:range.location];
    NSRange r = [name rangeOfString:@"."];
    
    NSString *resolutionH = [NSString stringWithFormat:@"%d",(int)[[UIScreen mainScreen] scale] * (int)[UIScreen mainScreen].bounds.size.width];
    NSString *resolutionV = [NSString stringWithFormat:@"%d",(int)[[UIScreen mainScreen] scale] * (int)[UIScreen mainScreen].bounds.size.height];
    NSString *pixelsName = [NSString stringWithFormat:@"%@/%@_%@x%@%@",path,[name substringToIndex:r.location],resolutionH,resolutionV,[name substringFromIndex:r.location]];
    
    return pixelsName;
}

@end

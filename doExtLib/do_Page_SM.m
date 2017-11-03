//
//  do_Page_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Page_SM.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doScriptEngineHelper.h"
#import "doISingletonModuleFactory.h"
#import "doIMultitonModuleFactory.h"
#import "doIGlobal.h"

#import "doIPageView.h"
#import "doSourceFile.h"
#import "doIScriptEngine.h"
#import "doServiceContainer.h"
#import "doIUIModuleFactory.h"
#import "doIUIModuleView.h"
#import "doUIModule.h"
#import "doIScriptEngineFactory.h"
#import "doSourceFile.h"
#import "doISourceFS.h"
#import "doUIContainer.h"

@implementation do_Page_SM
{
    NSMutableDictionary * dictUIModuleAddresses;
    NSMutableDictionary * dictModuleAddresses;
    NSMutableDictionary * dictModuleID;
}
@synthesize CurrentApp = _CurrentApp;
@synthesize PageView = _PageView;
@synthesize UIFile = _UIFile;
@synthesize ScriptEngine = _ScriptEngine;
@synthesize RootView = _RootView;
@synthesize Data = _Data;
@synthesize statusBarState;
@synthesize SoftMode;
@synthesize DesignScreenHeight = _DesignScreenHeight;
@synthesize DesignScreenWidth = _DesingScreenWidth;
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
#pragma mark - init
- (id)init:(id<doIApp>)_doApp :(id<doIPageView>)_pageView :(doSourceFile *)_uiFile {
    self = [super init];
    if(self)
    {
        _CurrentApp = _doApp;
        _PageView = _pageView;
        _UIFile = _uiFile;
        
        _DesignScreenHeight = [doServiceContainer Instance].Global.ScreenHeight;
        _DesingScreenWidth = [doServiceContainer Instance].Global.ScreenWidth;
    }
    
    return self;
}
-(void) dealloc
{
    NSLog(@"doPage dealloc......");
}
#pragma mark -
#pragma mark - override
- (void)OnInit{
    [super OnInit];
    dictUIModuleAddresses = [[NSMutableDictionary alloc]init];
    dictModuleAddresses= [[NSMutableDictionary alloc]init];
    dictModuleID = [[NSMutableDictionary alloc]init];
}

- (void)Dispose{
    [[doServiceContainer Instance].SingletonModuleFactory RemoveSingletonModuleByAddress:self.UniqueKey];
    if (dictUIModuleAddresses != nil) {
        [dictUIModuleAddresses removeAllObjects];
        dictUIModuleAddresses = nil;
    }
    
    if (_ScriptEngine != nil) {
        [_ScriptEngine Dispose];
        _ScriptEngine = nil;
    }
    [dictModuleID removeAllObjects];
    dictModuleID = nil;
    /*pagemodel不需要再调用pageview的dispse会死循环
     if (_PageView != nil) {
     [_PageView DisposeView];
     _PageView = nil;
     }*/
    if (dictModuleAddresses != nil)
    {
        NSMutableDictionary* temp = [[NSMutableDictionary alloc]initWithDictionary:dictModuleAddresses copyItems:NO];
        //释放每一个子Model
        for(doMultitonModule* _moduleModel in [temp allValues])
        {
            [_moduleModel Dispose];
        }
        [temp removeAllObjects];
        [dictModuleAddresses removeAllObjects];
        dictModuleAddresses = nil;
    }
    
    if(_RootView!=nil)
    {
        [_RootView Dispose];
        _RootView = nil;
    }
    [super Dispose];
}

- (doUIModule *) CreateUIModule: (doUIContainer *)_uiContainer : (NSDictionary *) _moduleNode
{
    NSString * _typeID =[doJsonHelper GetOneText: _moduleNode:@"type" :@""];
    doUIModule * _uiModule = [[doServiceContainer Instance].UIModuleFactory CreateUIModule:_typeID];
    if (_uiModule == nil) {
        [NSException raise:@"doPage" format:@"%@中遇到无效的UI组件：%@",_UIFile.FileFullName,_typeID,nil];
    }
    _uiModule.CurrentPage = self;
    _uiModule.CurrentUIContainer = _uiContainer;
    [_uiModule  LoadModel:_moduleNode ];
    [[doServiceContainer Instance].UIModuleFactory BindUIModuleView:_uiModule];
    
    [dictUIModuleAddresses setObject:_uiModule forKey:_uiModule.UniqueKey];
    [_uiModule LoadView];
    [_uiContainer RegistChildUIModule:_uiModule.ID :_uiModule];
    return _uiModule;
}
- (void) RemoveUIModule: (doUIModule *)_module
{
    [dictUIModuleAddresses removeObjectForKey:_module.UniqueKey];
}
- (void)LoadRootUiContainer{
    doUIContainer* _container = [[doUIContainer alloc]init:self];
    [_container LoadFromFile:self.UIFile:nil:nil];
    _RootView = _container.RootView;
}

- (void)LoadScriptEngine:(NSString *)_scriptFile :(NSString *)_fileFullName{
    NSString *_scriptType = self.PageView.CustomScriptType;
    if (!_scriptType || [_scriptType isEqualToString:@""]) {
        _scriptType = [doServiceContainer Instance].Global.ScriptType;
    }
    NSString *_fileName = [_fileFullName lastPathComponent];
    NSString *_scriptFileName = [NSString stringWithFormat:@"%@%@",_fileName,_scriptType];
    _ScriptEngine = [[doServiceContainer Instance].ScriptEngineFactory CreateScriptEngine:self.CurrentApp :self :self.PageView.CustomScriptType :_scriptFileName];
    if (self.ScriptEngine == nil) {
        [NSException raise:@"doPage" format:@"%@中的脚本类型无效：%@",_UIFile.FileFullName,_scriptType,nil];
    }
    if (_scriptFile != nil && _scriptFile.length > 0) {
        if(_RootView!=nil)
            [_RootView.UIContainer LoadDefalutScriptFile:_scriptFile :_scriptType];
    }
}

- (doUIModule *)GetUIModuleByAddress:(NSString *)_key{
    if (![dictUIModuleAddresses objectForKey:_key]) {
        return nil;
    }
    return [dictUIModuleAddresses objectForKey:_key];
}

-(doMultitonModule*) CreateMultitonModule:(NSString*) _typeID :(NSString*) _id
{
    if (_typeID == nil || _typeID.length <= 0) @throw [[NSException alloc] initWithName:@"未指定Model组件的type值" reason:nil userInfo:nil];
    doMultitonModule* _moduleModel = nil;
    NSString* tempId = nil;
    if(_id!=nil&&_id.length>0)
        tempId = [_typeID stringByAppendingString:_id];
    
    if(tempId!=nil&&dictModuleID[tempId]!=nil){
        _moduleModel = dictModuleAddresses[dictModuleID[tempId]];
    }else{
        _moduleModel = [[doServiceContainer Instance].MultitonModuleFactory CreateMultitonModule:_typeID];
        if (_moduleModel == nil)
            [NSException raise:@"doPage" format:@"遇到无效的Model组件:%@",_typeID,nil];
        _moduleModel.CurrentPage = self;
        _moduleModel.CurrentApp = self.CurrentApp;
        dictModuleAddresses[_moduleModel.UniqueKey] = _moduleModel;
        if(tempId!=nil){
            dictModuleID[tempId] = _moduleModel.UniqueKey;
        }
    }
    return _moduleModel;
}

-(BOOL) DeleteMultitonModule:(NSString*) _address
{
    doMultitonModule* _moduleModel = [self GetMultitonModuleByAddress:_address];
    if (_moduleModel == nil) return NO;
    [dictModuleAddresses removeObjectForKey:_address];
    for(NSString* key in dictModuleID.allKeys)
    {
        if([dictModuleID[key] isEqualToString:_address])
        {
            [dictModuleID removeObjectForKey:key];
            break;
        }
    }
    return true;
}

-(doMultitonModule*) GetMultitonModuleByAddress:(NSString*) _key
{
    if (![[dictModuleAddresses allKeys] containsObject:_key]) return nil;
    return dictModuleAddresses[_key];
}

#pragma mark -
#pragma mark - private
//获取从上一层page传递过来的数据 同步
- (void)getData:(NSArray*) parms
{
    //    NSDictionary * _dictParas =[parms objectAtIndex:0];
    //    id<doIScriptEngine> _scriptEngine =[parms objectAtIndex:1];
    doInvokeResult * _invokeResult = [parms objectAtIndex:2];
    [_invokeResult SetResultText:self.Data];
}

- (void)remove:(NSArray *)parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _id = [doJsonHelper GetOneText: _dictParas: @"id" :@""];
    doUIModule* _ui = nil;
    if(_id==nil||_id.length<=0)
    {
        [NSException raise:@"doPage" format:@"id不能为空",nil];
    }else{
        _ui = [doScriptEngineHelper ParseUIModule:_scriptEngine :_id ];
    }
    if(_ui!=nil){
        UIView* _view = (UIView*) _ui.CurrentUIModuleView;
        if(_view!=nil){
            [_view removeFromSuperview];
            [_ui Dispose];
        }
    }
}

- (void)hideKeyboard:(NSArray *)parms
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (void)supportPanClosePage:(NSArray *)parms
{
    _PageView.supportCloseParms = parms;
}
- (void)setDesignScreenResolution:(double)screenWidth :(double)screenHeight
{
    _DesingScreenWidth = screenWidth;
    _DesignScreenHeight = screenHeight;
}

@end
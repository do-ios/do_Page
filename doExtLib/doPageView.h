//
//  doPageView.h
//  doDebuger
//
//  Created by 刘吟 on 14/12/9.
//  Copyright (c) 2014年 deviceone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "doIPageView.h"
@interface doPageView : UIViewController<doIPageView>
-(id)init:(NSString *) _appID : (NSString *) _uiPath : (NSString *) _scriptType :(NSString *) _animationType :(NSString *) _data : (NSString *) _statusState :(NSString *) _keyboardMode :(NSString*)fgColor :(NSString *)Id :(NSString *)statusBarBgColor;

@end

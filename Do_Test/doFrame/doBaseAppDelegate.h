//
//  doBaseAppDelegate.h
//  DoFrame
//
//  Created by 刘吟 on 15/5/21.
//  Copyright (c) 2015年 DongXian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "doIAppDelegate.h"
#import "doIAppSecurity.h"

@interface doBaseAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) id<doIAppSecurity> AppSecurityInfo;

-(UIViewController*) GetRootViewController;
-(NSString*) GetLaunchType;
-(NSString *) GetLaunchData;
-(void) InitAppDelegate;
-(void) AddAppDelegate:(id<doIAppDelegate>) appDelegate;
@end

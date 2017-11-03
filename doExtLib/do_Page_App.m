//
//  do_Page_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Page_App.h"
static do_Page_App* instance;
@implementation do_Page_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Page_App alloc]init];
    return instance;
}
@end

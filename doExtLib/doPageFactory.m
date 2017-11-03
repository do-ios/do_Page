//
//  doPageFactory.m
//  DoFrame
//
//  Created by sqs on 14/11/26.
//  Copyright (c) 2014年 DongXian. All rights reserved.
//

#import "doPageFactory.h"
#import "do_Page_SM.h"

@implementation doPageFactory
#pragma mark -
#pragma mark - override
- (id<doIPage>) CreatePage :(id<doIApp>) _doApp : (id<doIPageView>) _pageView : (doSourceFile *) _uiFile
{

    return  [[do_Page_SM alloc]init:_doApp : _pageView : _uiFile];

}
@end

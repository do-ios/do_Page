//
//  doDataFS.h
//  DoFrame
//
//  Created by zhangwd on 14-11-20.
//  Copyright (c) 2014年 DongXian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "doIDataFS.h"
#import "doIApp.h"

@interface doDataFS : NSObject<doIDataFS>

- (id)init:(id<doIApp>)_doApp;

@end

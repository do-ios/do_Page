//
//  do_Page_SM.h
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Page_ISM.h"
#import "doSingletonModule.h"
#import "doIPage.h"

@interface do_Page_SM : doSingletonModule<do_Page_ISM,doIPage>

- (id)init:(id<doIApp>)_doApp :(id<doIPageView>)_pageView :(doSourceFile *)_uiFile ;
@end
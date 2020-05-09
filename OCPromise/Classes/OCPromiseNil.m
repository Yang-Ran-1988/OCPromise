//
//  OCPromiseNil.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCPromiseNil.h"
#import <objc/runtime.h>

@implementation OCPromiseNil

id NENilMethod(id self,SEL cmd) {
    return nil;
}

+ (instancetype)nilValue {
    static id singleton;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        singleton = [[self alloc] init];
    });

    return singleton;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    class_addMethod(self, sel, (IMP)NENilMethod, "@@:");
    return [super resolveInstanceMethod:sel];
}

@end

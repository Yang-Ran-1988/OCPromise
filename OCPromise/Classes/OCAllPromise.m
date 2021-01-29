//
//  OCAllPromise.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCAllPromise.h"
#import "OCPromiseNil.h"
#import "OCPromiseReturnValue.h"

@implementation OCAllPromise

@synthesize promise = _promise;
@synthesize promises = _promises;

+ (instancetype)initWithPromises:(NSArray *)promises {
    OCAllPromise *allPromise = [[OCAllPromise alloc] initWithPromises:promises];
    allPromise.type = OCPromiseTypeAll;
    return allPromise;
}

- (instancetype)initWithPromises:(NSArray *)promises {
    self = [super initWithPromis:nil withInput:nil];
    if (self) {
        _promises = [super buildPromisesCopy:promises];
        @weakify(self)
        _promise = ^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            @strongify(self)
            if (!self.promises.count) {
                resolve([[OCPromiseReturnValue alloc] init]);
                return;
            }
            
            dispatch_semaphore_t returnLock = dispatch_semaphore_create(0);
            dispatch_semaphore_t innerLock = dispatch_semaphore_create(1);
            __block BOOL isResolve = YES;
            __block id returnValue = [[OCPromiseReturnValue alloc] init];
            
            for (NSUInteger idx = 0; idx < self.promises.count && isResolve; idx++) {
                __kindof OCPromise *obj = self.promises[idx];
                obj.last = self.last;
                obj.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    @strongify(self)
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    if (isResolve) {
                        if ([value isKindOfClass:[OCPromiseReturnValue class]]) {
                            returnValue[idx] = value;
                        }
                        else {
                            returnValue[idx] = (self.mapBlock ? self.mapBlock(value) : value) ?: OCPromiseNil.nilValue;
                        }
                        if (((OCPromiseReturnValue *)returnValue).count == self.promises.count) {
                            dispatch_semaphore_signal(returnLock);
                        }
                    }
                    
                    dispatch_semaphore_signal(innerLock);
                    return nil;
                    
                })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    if (!isResolve) {
                        dispatch_semaphore_signal(innerLock);
                        return nil;
                    }
                    isResolve = NO;
                    returnValue = value;
                    dispatch_semaphore_signal(returnLock);
                    dispatch_semaphore_signal(innerLock);
                    return nil;
                }));
            }
            
            dispatch_semaphore_wait(returnLock, DISPATCH_TIME_FOREVER);
            
            if (isResolve) {
                resolve(returnValue);
            } else {
                reject(returnValue);
            }
        };
    }
    return self;
}

@end

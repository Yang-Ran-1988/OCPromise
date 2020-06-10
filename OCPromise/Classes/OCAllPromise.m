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

@interface OCAllPromise ()

@property (nonatomic, copy) NSArray <__kindof OCPromise *> *promises;

@end

@implementation OCAllPromise

@synthesize promise = _promise;
@synthesize promises = _promises;
@synthesize mapBlock = _mapBlock;

+ (instancetype)initWithPromises:(NSArray<__kindof OCPromise *> *)promises {
    OCAllPromise *allPromise = [[OCAllPromise alloc] initWithPromises:promises];
    allPromise.type = OCPromiseTypeAll;
    return allPromise;
}

- (instancetype)initWithPromises:(NSArray<__kindof OCPromise *> *)promises {
    self = [super initWithPromis:nil withInput:nil];
    if (self) {
        _promises = [super buildPromisesCopy:promises];
        __weak typeof(self) weakSelf = self;
        
        _promise = ^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf.promises.count) {
                resolve([[OCPromiseReturnValue alloc] init]);
                return;
            }
            
            dispatch_semaphore_t returnLock = dispatch_semaphore_create(0);
            dispatch_semaphore_t innerLock = dispatch_semaphore_create(1);
            __block BOOL isResolve = YES;
            __block id returnValue = [[OCPromiseReturnValue alloc] init];
            
            for (NSUInteger idx = 0; idx < strongSelf.promises.count && isResolve; idx++) {
                __kindof OCPromise *obj = strongSelf.promises[idx];
                obj.last = strongSelf.last;
                obj.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    if (isResolve) {
                        if ([value isKindOfClass:[OCPromiseReturnValue class]]) {
                            returnValue[idx] = value;
                        }
                        else {
                            returnValue[idx] = (strongSelf.mapBlock ? strongSelf.mapBlock(value) : value) ?: OCPromiseNil.nilValue;
                        }
                        if (((OCPromiseReturnValue *)returnValue).count == strongSelf.promises.count) {
                            dispatch_semaphore_signal(returnLock);
                        }
                    }
                    
                    dispatch_semaphore_signal(innerLock);
                    return nil;
                    
                })).innerCatch(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    
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

- (void)setMapBlock:(mapBlock)mapBlock {
    _mapBlock = mapBlock;
    [self injectMapBlock];
}

- (void)injectMapBlock {
    dispatch_apply(self.promises.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
        id obj = self.promises[index];
        if ([obj isKindOfClass:[OCAllPromise class]]) {
            ((OCAllPromise *) obj).mapBlock = _mapBlock;
            [obj injectMapBlock];
        }
    });
}

@end

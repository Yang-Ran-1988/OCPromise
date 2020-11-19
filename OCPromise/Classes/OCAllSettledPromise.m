//
//  OCAllSettledPromise.m
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/6/15.
//

#import "OCAllSettledPromise.h"
#import "OCPromiseNil.h"
#import "OCPromiseReturnValue.h"

@implementation OCAllSettledPromise

@synthesize promise = _promise;
@synthesize promises = _promises;
@synthesize mapBlock = _mapBlock;

+ (instancetype)initWithPromises:(NSArray *)promises {
    OCAllSettledPromise *allSettledPromise = [[OCAllSettledPromise alloc] initWithPromises:promises];
    allSettledPromise.type = OCPromiseTypeAllSettled;
    return allSettledPromise;
}

- (instancetype)initWithPromises:(NSArray *)promises {
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
            __block id returnValue = [[OCPromiseReturnValue alloc] init];
            
            for (NSUInteger idx = 0; idx < strongSelf.promises.count; idx++) {
                __kindof OCPromise *obj = strongSelf.promises[idx];
                obj.last = strongSelf.last;
                obj.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    
                    if ([value isKindOfClass:[OCPromiseReturnValue class]]) {
                        returnValue[idx] = @{@"value":value,
                                             @"status":OCPromiseAllSettledFulfilled};
                    }
                    else {
                        returnValue[idx] = [NSDictionary dictionaryWithObjectsAndKeys:OCPromiseAllSettledFulfilled, @"status",
                                            strongSelf.mapBlock ? strongSelf.mapBlock(value) : value, @"value",nil];
                    }
                    if (((OCPromiseReturnValue *)returnValue).count == strongSelf.promises.count) {
                        dispatch_semaphore_signal(returnLock);
                    }
                    
                    dispatch_semaphore_signal(innerLock);
                    return nil;
                    
                })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    
                    returnValue[idx] = [NSDictionary dictionaryWithObjectsAndKeys:OCPromiseAllSettledRejected, @"status", value, @"value", nil];
                    if (((OCPromiseReturnValue *)returnValue).count == strongSelf.promises.count) {
                        dispatch_semaphore_signal(returnLock);
                    }
                    dispatch_semaphore_signal(innerLock);
                    return nil;
                    
                }));
            }
            
            dispatch_semaphore_wait(returnLock, DISPATCH_TIME_FOREVER);
            
            resolve(returnValue);
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
        if ([obj isKindOfClass:[OCSetPromise class]]) {
            ((OCSetPromise *) obj).mapBlock = _mapBlock;
            [obj injectMapBlock];
        }
    });
}

@end

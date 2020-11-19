//
//  OCAnyPromise.m
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/6/15.
//

#import "OCAnyPromise.h"
#import "OCPromiseReturnValue.h"

@implementation OCAnyPromise

@synthesize promise = _promise;
@synthesize promises = _promises;

+ (instancetype)initWithPromises:(NSArray *)promises {
    OCAnyPromise *allPromise = [[OCAnyPromise alloc] initWithPromises:promises];
    allPromise.type = OCPromiseTypeAny;
    return allPromise;
}

- (instancetype)initWithPromises:(NSArray *)promises {
    self = [super initWithPromis:nil withInput:nil];
    if (self) {
        _promises = [super buildPromisesCopy:promises];
        __weak typeof(self) weakSelf = self;
        
        _promise = ^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf.promises.count) {
                resolve(nil);
                return;
            }
            
            dispatch_semaphore_t returnLock = dispatch_semaphore_create(0);
            dispatch_semaphore_t innerLock = dispatch_semaphore_create(1);
            __block id returnValue = nil;
            __block BOOL isResolve = NO;
            __block BOOL isReject = NO;
            __block NSUInteger rejectCount = 0;
            
            for (NSUInteger idx = 0; idx < strongSelf.promises.count && !isResolve && !isReject; idx++) {
                __kindof OCPromise *obj = strongSelf.promises[idx];
                obj.last = strongSelf.last;
                obj.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    if (isResolve || isReject) {
                        dispatch_semaphore_signal(innerLock);
                        return nil;
                    }
                    
                    returnValue = value;
                    isResolve = YES;
                    dispatch_semaphore_signal(returnLock);
                    dispatch_semaphore_signal(innerLock);
                    return nil;
                    
                })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
                    
                    dispatch_semaphore_wait(innerLock, DISPATCH_TIME_FOREVER);
                    if (isResolve || isReject) {
                        dispatch_semaphore_signal(innerLock);
                        return nil;
                    }
                    rejectCount ++;
                    if (rejectCount == strongSelf.promises.count) {
                        NSError *error = [NSError errorWithDomain:OCPromiseAggregateErrorDomain code:OCPromiseErrorAggregateError userInfo:@{NSLocalizedDescriptionKey:@"All Promises rejected"}];
                        returnValue = error;
                        isReject = YES;
                        dispatch_semaphore_signal(returnLock);
                    }
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

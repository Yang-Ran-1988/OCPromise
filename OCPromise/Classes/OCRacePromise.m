//
//  OCRacePromise.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCRacePromise.h"

@interface OCRacePromise ()

@property (nonatomic, copy) NSArray <__kindof OCPromise *> *promises;

@end

@implementation OCRacePromise

@synthesize promise = _promise;
@synthesize promises = _promises;

+ (instancetype)initWithPromises:(NSArray<__kindof OCPromise *> *)promises {
    OCRacePromise *racePromise = [[OCRacePromise alloc] initWithPromises:promises];
    racePromise.type = OCPromiseTypeRace;
    return racePromise;
}

- (instancetype)initWithPromises:(NSArray<__kindof OCPromise *> *)promises {
    self = [super initWithPromis:nil withInput:nil];
    if (self) {
        _promises = [super buildPromisesCopy:promises];
        if (!_promises.count) {
            [self cancel];
            return nil;
        }
        
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
                    
                    returnValue = value;
                    isReject = YES;
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

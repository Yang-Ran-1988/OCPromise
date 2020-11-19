//
//  OCPromise.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/26.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCPromise.h"
#import "OCThenPromise.h"
#import "OCSetPromise.h"
#import "OCPromise+Private.h"

NSErrorDomain const OCPromiseAggregateErrorDomain = @"OCPromiseAggregateErrorDomain";
NSString * const OCPromiseAllSettledFulfilled = @"fulfilled";
NSString * const OCPromiseAllSettledRejected = @"rejected";

@interface OCPromise ()

@end

@implementation OCPromise

OCPromise * Promise(promise promise) {
    OCPromise *ocPromise = [OCPromise promise:promise withInput:nil];
    return ocPromise;
}

OCPromise * function(inputPromise inputPromise) {
    return [OCPromise promise:nil withInput:inputPromise];
}

OCPromise * retry(OCPromise *ocPromise, uint8_t times, int64_t delay/*ms*/) {
    OCPromise *retryPromise = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        __block uint8_t count = 0;
        ocPromise.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
            resolve(value);
            return nil;
        })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
            count ++;
            if (count == times) {
                reject(value);
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), ocPromise.promiseSerialQueue, ^{
                    ocPromise.status = ocPromise.status & ~OCPromiseStatusFulfilled & ~OCPromiseStatusPending;
                    ocPromise.promise(ocPromise.resolve, ocPromise.reject);
                });
            }
            return nil;
        }));
    });
    return retryPromise;
}


+ (instancetype)promise:(promise)ownPromise withInput:(inputPromise)input {
    OCPromise *ocPromise = [[OCThenPromise alloc] initWithPromis:ownPromise withInput:input];
    return ocPromise;
}

- (instancetype)initWithPromis:(promise)ownPromise withInput:(inputPromise)input {
    self = [super init];
    if (self) {
        _promise = ownPromise;
        _inputPromise = input;
    }
    return self;
}

- (then)then {
    __weak typeof(self) weakSelf = self;
    return ^(__kindof OCPromise *_Nonnull then) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        return [strongSelf buildNewPromiseIntoNextWithOrigin:then type:then.type];
    };
}

- (catch)catch {
    __weak typeof(self) weakSelf = self;
    return ^OCPromise * _Nullable (__kindof OCPromise *_Nonnull then) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        return [strongSelf buildNewPromiseIntoNextWithOrigin:then type:OCPromiseTypeCatch];
    };
}

- (catchOnMain)catchOnMain {
    __weak typeof(self) weakSelf = self;
    return ^(deliverValue deliverValue) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        OCPromise *promise = function(^OCPromise * _Nullable(id  _Nonnull value) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !deliverValue ?: deliverValue(value);
            });
            return nil;
        });
        return [strongSelf buildNewPromiseIntoNextWithOrigin:promise type:OCPromiseTypeCatch];
    };
}

- (finally)finally {
    __weak typeof(self) weakSelf = self;
    return ^OCPromise * _Nullable (deliverFinal deliver) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        OCPromise *promise = function(^OCPromise * _Nullable(id  _Nonnull value) {
            !deliver ?: deliver();
            return nil;
        });
        return [strongSelf buildNewPromiseIntoNextWithOrigin:promise type:OCPromiseTypeFinally];
    };
}

- (finallyOnMain)finallyOnMain {
    __weak typeof(self) weakSelf = self;
    return ^OCPromise * _Nullable (deliverFinal deliver) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        OCPromise *promise = function(^OCPromise * _Nullable(id  _Nonnull value) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !deliver ?: deliver();
            });
            return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
                resolve(value);
            });
        });
        return [strongSelf buildNewPromiseIntoNextWithOrigin:promise type:OCPromiseTypeFinally];
    };
}

- (deliverOnMainThread)deliverOnMainThread {
    __weak typeof(self) weakSelf = self;
    return ^(deliverValue deliverValue) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        OCPromise *promise = function(^OCPromise * _Nullable(id  _Nonnull value) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !deliverValue ?: deliverValue(value);
            });
            return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
                resolve(value);
            });
        });
        return [strongSelf buildNewPromiseIntoNextWithOrigin:promise type:OCPromiseTypeThen];
    };
}

- (map)map {
    __weak typeof(self) weakSelf = self;
    return ^(mapBlock mapBlock) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        OCPromise *promise = function(^OCPromise * _Nullable(id  _Nonnull value) {
            return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
                resolve(mapBlock?mapBlock(value):value);
            });
        });
        return [strongSelf buildNewPromiseIntoNextWithOrigin:promise type:OCPromiseTypeThen];
    };
}

- (OCPromise *)buildNewPromiseIntoNextWithOrigin:(OCPromise *)promise type:(OCPromiseType)type {
    if (!promise.last && !promise.next) {
        promise.type = type;
        return promise;
    }
    
    return [self buildNewPromiseWithPromise:promise andType:type];
}

- (OCPromise *)buildNewPromiseWithPromise:(OCPromise *)promise andType:(OCPromiseType)type {
    OCPromise *newPromise;
    if (promise.status & OCPromiseStatusInSet) {
        promise.type = type;
        return promise;
    }
    
    switch (promise.type) {
        case OCPromiseTypeAll:
            newPromise = [OCSetPromise initAllWithPromises:promise.promises];
            break;
        case OCPromiseTypeRace:
            newPromise = [OCSetPromise initRaceWithPromises:promise.promises];
            break;
        case OCPromiseTypeAny:
            newPromise = [OCSetPromise initAnyWithPromises:promise.promises];
            break;
        case OCPromiseTypeAllSettled:
            newPromise = [OCSetPromise initAllSettledWithPromises:promise.promises];
            break;
        default:
            newPromise = [OCPromise promise:promise.promise withInput:promise.inputPromise];
            break;
    }
    
    newPromise.type = type;
    newPromise.code = promise.code*100;
    
    return newPromise;
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray *))all {
    return ^(NSArray <__kindof OCPromise *> * all) {
        return [OCSetPromise initAllWithPromises:all];
    };
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray *))race {
    return ^(NSArray <__kindof OCPromise *> * race) {
        return [OCSetPromise initRaceWithPromises:race];
    };
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray *))any {
    return ^(NSArray <__kindof OCPromise *> * any) {
        return [OCSetPromise initAnyWithPromises:any];
    };
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray *))allSettled {
    return ^(NSArray <__kindof OCPromise *> * any) {
        return [OCSetPromise initAllSettledWithPromises:any];
    };
}

+ (OCPromise * _Nullable (^)(id _Nonnull))reject {
    return ^(id _Nonnull rejectValue) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            reject(rejectValue);
        });
    };
}

+ (OCPromise * _Nullable (^)(id _Nonnull))resolve {
    return ^(id _Nonnull resolveValue) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            resolve(resolveValue);
        });
    };
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray *, mapBlock))map {
    return ^(NSArray <__kindof OCPromise *> * all, mapBlock mapBlock) {
        OCSetPromise *allPromise = [OCSetPromise initAllWithPromises:all];
        allPromise.mapBlock = mapBlock;
        return allPromise;
    };
}

- (void)cancel {
    NSString *reason = [NSString stringWithFormat:@"%@ must be overridden by subclasses", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}

- (void)setStatus:(OCPromiseStatus)status {
    _status = status;
    if (_status & OCPromiseStatusRejected) {
        _status |= OCPromiseStatusFulfilled;
    }
    if (_status & OCPromiseStatusFulfilled) {
        _head = nil;
    }
}

@end

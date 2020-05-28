//
//  OCThenPromise.m
//  test
//
//  Created by 新东方_杨然 on 2020/5/8.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCThenPromise.h"
#import "OCPromiseReturnValue.h"
#import "OCPromiseNil.h"
#import "OCPromise+PrivateInit.h"

@interface OCThenPromise ()

@end

@implementation OCThenPromise

@synthesize resolve = _resolve;
@synthesize reject = _reject;

- (instancetype)initWithPromis:(promise)ownPromise withInput:(inputPromise)input {
    self = [super initWithPromis:ownPromise withInput:input];
    if (self) {
        __weak typeof(self) weakSelf = self;
        _resolve = ^(id  _Nonnull resolve) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            dispatch_block_t block = ^{
                strongSelf.status |= OCPromiseStatusTriggered;
                id resolveValue = resolve;
                strongSelf.triggerValue = resolveValue;
                if (strongSelf.next) {
                    [strongSelf.next receiveResolveValueAndTriggerPromise:resolveValue];
                }
            };
            dispatch_promise_queue_async_safe(strongSelf.promiseSerialQueue, block);
            return strongSelf;
        };
        _reject = ^(id  _Nonnull reject) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            dispatch_block_t block = ^{
                strongSelf.status |= OCPromiseStatusTriggered;
                [strongSelf searchNextCatchWithRejectValue:reject];
                [strongSelf searchFinallyWithValue:reject];
                [strongSelf cancel];
            };
            dispatch_promise_queue_async_safe(strongSelf.promiseSerialQueue, block);
            return strongSelf;
        };
    }
    return self;
}

- (void)receiveResolveValueAndTriggerPromise:(id)resolveValue {
    if (self.type != OCPromiseTypeCatch || self.type != OCPromiseTypeFinally) {
        if (self.inputPromise) {
            self.promise = self.inputPromise(resolveValue).promise;
        }
        [self injectResolveValueIntoPromises:resolveValue];
        if (!self.promise) {
            [self searchFinallyWithValue:resolveValue];
            [self cancel];
        }
        else {
            if (!self.realPromises.count) {
                if (self.promise && !(self.status & OCPromiseStatusTriggered || self.status & OCPromiseStatusTriggering)) {
                    self.status |= OCPromiseStatusTriggering;
                    self.promise(self.resolve, self.reject);
                }
            }
            else {
                [self triggerRealPromisesWithResolveValue];
            }
        }
    }
    else if (self.type == OCPromiseTypeFinally) {
        if (self.inputPromise && !(self.status & OCPromiseStatusTriggered || self.status & OCPromiseStatusTriggering)) {
            self.status |= OCPromiseStatusTriggered;
            self.inputPromise(resolveValue);
        }
        [self cancel];
    }
}

- (void)triggerRealPromisesWithResolveValue {
    if (self.promise) {
        [self.realPromises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.promise) {
                obj.promise = self.promise;
            }
            if (obj.promise && !(obj.status & OCPromiseStatusTriggered || obj.status & OCPromiseStatusTriggering)) {
                obj.status |= OCPromiseStatusTriggering;
                obj.promise(obj.resolve, obj.reject);
            }
        }];
    }
}

- (void)injectResolveValueIntoPromises:(id)resolveValue {
    [self.promises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_block_t block = ^{
            if (obj.inputPromise) {
                obj.promise = obj.inputPromise(resolveValue).promise;
            }
            [obj injectResolveValueIntoPromises:resolveValue];
        };
        dispatch_promise_queue_async_safe(obj.promiseSerialQueue, block);
    }];
    [self.realPromises enumerateObjectsUsingBlock:^(__kindof OCThenPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj injectResolveValueIntoPromises:resolveValue];
    }];
}

- (void)searchNextCatchWithRejectValue:(id)value {
    self.triggerValue = value;
    self.status |= OCPromiseStatusCatchError;
    if (self.next) {
        if (self.next.type == OCPromiseTypeCatch && self.next.inputPromise && !(self.next.status & OCPromiseStatusTriggered || self.next.status & OCPromiseStatusTriggering)) {
            self.next.status |= OCPromiseStatusTriggered;
            self.next.inputPromise(value);
        }
        [self.next searchNextCatchWithRejectValue:value];
    }
    if (self.realPromises) {
        [self.realPromises enumerateObjectsUsingBlock:^(__kindof OCThenPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj searchNextCatchWithRejectValue:value];
        }];
    }
}

- (void)searchFinallyWithValue:(id)value {
    self.status |= OCPromiseStatusTriggered;
    if (self.next) {
        if (self.next.type == OCPromiseTypeFinally && self.next.inputPromise && !(self.next.status & OCPromiseStatusTriggered)) {
            self.next.status |= OCPromiseStatusTriggered;
            self.next.inputPromise(value);
        }
        [self.next searchFinallyWithValue:value];
    }
    
    if (self.realPromises) {
        [self.realPromises enumerateObjectsUsingBlock:^(__kindof OCThenPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj searchFinallyWithValue:value];
        }];
    }
}

- (OCPromise *)buildNewPromiseWithOrigin:(OCPromise *)promise intoNextWithType:(OCPromiseType)type {
    
    OCThenPromise *currentPromise;
    dispatch_queue_t promiseSerialQueue;
    
    if (self.status & OCPromiseStatusInSet) {
        currentPromise = self;
    }
    else {
        currentPromise = (OCThenPromise *)[super buildNewPromiseWithPromise:self andType:self.type];
    }
    
    if (!currentPromise.promiseSerialQueue) {
        NSString *ptr = [NSString stringWithFormat:@"promise_serial_queue%lu",(uintptr_t)self];
        promiseSerialQueue = dispatch_queue_create([ptr UTF8String], DISPATCH_QUEUE_SERIAL);
        currentPromise.promiseSerialQueue = promiseSerialQueue;
    }
    else {
        promiseSerialQueue = currentPromise.promiseSerialQueue;
    }
    
    OCPromise *newPromise = [super buildNewPromiseWithOrigin:promise intoNextWithType:type];

    newPromise.last = currentPromise;
    newPromise.status = currentPromise.status;
    newPromise.status &= (~OCPromiseStatusTriggered);
    newPromise.status &= (~OCPromiseStatusTriggering);
    if (currentPromise.status & OCPromiseStatusCatchError) {
        newPromise.triggerValue = currentPromise.triggerValue;
    }
    if (!currentPromise.head) {
        newPromise.head = currentPromise;
    }
    else {
        newPromise.head = currentPromise.head;
    }
    currentPromise.next = newPromise;
    currentPromise.head = nil;
    newPromise.promiseSerialQueue = promiseSerialQueue;
    
    dispatch_block_t block = ^{
        if (currentPromise.status & OCPromiseStatusCatchError) {
            if ((currentPromise.type == OCPromiseTypeCatch || currentPromise.type == OCPromiseTypeFinally)
                && !(currentPromise.status & OCPromiseStatusTriggered || currentPromise.status & OCPromiseStatusTriggering)) {
                currentPromise.status |= OCPromiseStatusTriggered;
                currentPromise.inputPromise(currentPromise.triggerValue);
            }
            else {
                [currentPromise searchNextCatchWithRejectValue:currentPromise.triggerValue];
                [currentPromise searchFinallyWithValue:currentPromise.triggerValue];
            }
            [currentPromise cancel];
        }
        else {
            if (!currentPromise.last) {
                if (!(currentPromise.status & OCPromiseStatusTriggered) && currentPromise.inputPromise && !currentPromise.promise) {
#if DEBUG
                    NSString *reason = @"Head promise neez a input";
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                    currentPromise.inputPromise(nil);
#endif
                }
                if (currentPromise.promise && !(currentPromise.status & OCPromiseStatusTriggered || currentPromise.status & OCPromiseStatusTriggering)) {
                    currentPromise.status |= OCPromiseStatusTriggering;
                    currentPromise.promise(currentPromise.resolve, currentPromise.reject);
                }
                else {
                    [currentPromise cancel];
                }
            }
            else {
                if (currentPromise.last.status & OCPromiseStatusTriggered && !(currentPromise.status & OCPromiseStatusTriggered || currentPromise.status & OCPromiseStatusTriggering)) {
                    if (currentPromise.type == OCPromiseTypeCatch) {
                        [currentPromise searchFinallyWithValue:currentPromise.last.triggerValue];
                        [currentPromise cancel];
                    }
                    else {
                        if (currentPromise.inputPromise) {
                            currentPromise.promise = currentPromise.inputPromise(currentPromise.last.triggerValue).promise;
                        }
                        if (currentPromise.promise) {
                            currentPromise.status |= OCPromiseStatusTriggering;
                            currentPromise.promise(currentPromise.resolve, currentPromise.reject);
                        }
                        else {
                            if (currentPromise.next.type == OCPromiseTypeFinally) {
                                [currentPromise searchFinallyWithValue:currentPromise.last.triggerValue];
                            }
                            [currentPromise cancel];
                        }
                    }
                }
            }
        }
    };
    
    dispatch_promise_queue_async_safe(promiseSerialQueue, block);
    
    return newPromise;
}

- (void)cancel {
    if (self.realPromises.count) {
        [self.realPromises enumerateObjectsUsingBlock:^(OCThenPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj searchForwardAndSetCancel];
        }];
    }
    [self searchForwardAndSetCancel];
}

- (void)searchForwardAndSetCancel {
    self.head = nil;
    [self.next searchForwardAndSetCancel];
    self.next = nil;
}

@end

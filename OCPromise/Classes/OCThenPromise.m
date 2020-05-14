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
                strongSelf.status |= OCPRomiseStatusTriggered;
                id resolveValue = resolve;
                if ([resolve isMemberOfClass:[OCPromiseReturnValue class]]) {
                    OCPromiseReturnValue *returnValue = resolve;
                    if (returnValue.count == 0) {
                        resolveValue = OCPromiseNil.nilValue;
                    }
                    else if (returnValue.count == 1) {
                        resolveValue = returnValue[0];
                    }
                    else {
                        resolveValue = returnValue.array;
                    }
                }
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
                strongSelf.status |= OCPRomiseStatusTriggered;
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
            self.promise = self.inputPromise(resolveValue ?: OCPromiseNil.nilValue).promise;
        }
        [self injectResolveValueIntoPromises:resolveValue];
        if (!self.promise) {
            [self searchFinallyWithValue:resolveValue];
            [self cancel];
        }
        else {
            if (!self.realPromises.count) {
                if (self.promise && !(self.status & OCPRomiseStatusTriggered || self.status & OCPRomiseStatusTriggering)) {
                    self.status |= OCPRomiseStatusTriggering;
                    self.promise(self.resolve, self.reject);
                }
            }
            else {
                [self triggerRealPromisesWithResolveValue];
            }
        }
    }
    else if (self.type == OCPromiseTypeFinally) {
        if (self.inputPromise && !(self.status & OCPRomiseStatusTriggered || self.status & OCPRomiseStatusTriggering)) {
            self.status |= OCPRomiseStatusTriggered;
            self.inputPromise(resolveValue ?: OCPromiseNil.nilValue);
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
            if (obj.promise && !(obj.status & OCPRomiseStatusTriggered || obj.status & OCPRomiseStatusTriggering)) {
                obj.status |= OCPRomiseStatusTriggering;
                obj.promise(obj.resolve, obj.reject);
            }
        }];
    }
}

- (void)injectResolveValueIntoPromises:(id)resolveValue {
    [self.promises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_block_t block = ^{
            if (obj.inputPromise) {
                obj.promise = obj.inputPromise(resolveValue ?: OCPromiseNil.nilValue).promise;
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
    self.status |= OCPRomiseStatusCatchError;
    if (self.next) {
        if (self.next.type == OCPromiseTypeCatch && self.next.inputPromise && !(self.next.status & OCPRomiseStatusTriggered || self.next.status & OCPRomiseStatusTriggering)) {
            self.next.status |= OCPRomiseStatusTriggered;
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
    self.status |= OCPRomiseStatusTriggered;
    if (self.next) {
        if (self.next.type == OCPromiseTypeFinally && self.next.inputPromise && !(self.next.status & OCPRomiseStatusTriggered)) {
            self.next.status |= OCPRomiseStatusTriggered;
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
    
    if (self.status & OCPRomiseStatusInSet) {
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
    newPromise.status &= (~OCPRomiseStatusTriggered);
    newPromise.status &= (~OCPRomiseStatusTriggering);
    if (currentPromise.status & OCPRomiseStatusCatchError) {
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
        if (!currentPromise.last) {
            if (!(currentPromise.status & OCPRomiseStatusTriggered) && currentPromise.inputPromise && !currentPromise.promise && currentPromise.status != OCPRomiseStatusInSet) {
#if DEBUG
                NSString *reason = @"Head promise neez a input";
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                currentPromise.inputPromise(nil);
#endif
            }
            if (currentPromise.promise && !(currentPromise.status & OCPRomiseStatusTriggered || currentPromise.status & OCPRomiseStatusTriggering)) {
                currentPromise.status |= OCPRomiseStatusTriggering;
                currentPromise.promise(currentPromise.resolve, currentPromise.reject);
            }
            else {
                [currentPromise cancel];
            }
        }
        else {
            if (currentPromise.status & OCPRomiseStatusCatchError) {
                if (currentPromise.type == OCPromiseTypeCatch || currentPromise.type == OCPromiseTypeFinally) {
                    currentPromise.status |= OCPRomiseStatusTriggered;
                    currentPromise.inputPromise(currentPromise.triggerValue);
                }
                else {
                    [currentPromise searchNextCatchWithRejectValue:currentPromise.triggerValue];
                    [currentPromise searchFinallyWithValue:currentPromise.triggerValue];
                }
                [currentPromise cancel];
            }
            else {
                if (currentPromise.type == OCPromiseTypeCatch) {
                    [currentPromise searchFinallyWithValue:currentPromise.last.triggerValue];
                    [currentPromise cancel];
                }
                else {
                    if (currentPromise.last.status & OCPRomiseStatusTriggered && !(currentPromise.status & OCPRomiseStatusTriggered || currentPromise.status & OCPRomiseStatusTriggering)) {
                        if (currentPromise.inputPromise) {
                            currentPromise.promise = currentPromise.inputPromise(currentPromise.last.triggerValue).promise;
                        }
                        if (currentPromise.promise) {
                            currentPromise.status |= OCPRomiseStatusTriggering;
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

- (void)releaseLockForOnce {
    
}

@end

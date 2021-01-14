//
//  OCThenPromise.m
//  test
//
//  Created by 新东方_杨然 on 2020/5/8.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCThenPromise.h"

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
                if (strongSelf.status & OCPromiseStatusFulfilled && strongSelf.status & OCPromiseStatusRejected) {
                    return;
                }
                strongSelf.status |= OCPromiseStatusFulfilled;
                strongSelf.resolvedValue = resolve;
                if (strongSelf.next) {
                    [strongSelf.next triggerThePromiseWithResolveValue:resolve];
                }
            };
            dispatch_promise_queue_async_safe(strongSelf.promiseSerialQueue, block);
            return strongSelf;
        };
        _reject = ^(id  _Nonnull reject) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            dispatch_block_t block = ^{
                if (strongSelf.status & OCPromiseStatusFulfilled && !(strongSelf.status & OCPromiseStatusRejected)) {
                    return;
                }
                strongSelf.status |= OCPromiseStatusRejected;
                strongSelf.resolvedValue = reject;
                if (strongSelf.next) {
                    [strongSelf.next searchCatchWithRejectValue:reject];
                }
            };
            dispatch_promise_queue_async_safe(strongSelf.promiseSerialQueue, block);
            return strongSelf;
        };
    }
    return self;
}

- (OCPromise *)buildNewPromiseIntoNextWithOrigin:(OCPromise *)promise type:(OCPromiseType)type {
    
    OCThenPromise *currentPromise;
    dispatch_queue_t promiseSerialQueue;
    
    if (self.status & OCPromiseStatusInSet || !self.next) {
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
    
    OCPromise *newPromise = [super buildNewPromiseIntoNextWithOrigin:promise type:type];
    
    newPromise.last = currentPromise;
    newPromise.status = currentPromise.status & OCPromiseStatusInSet;
    if (currentPromise.status & OCPromiseStatusRejected) {
        newPromise.resolvedValue = currentPromise.resolvedValue;
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
        
        if ((currentPromise.status & OCPromiseStatusPending) != OCPromiseStatusPending) {
            if (!currentPromise.last) {
                if (currentPromise.inputPromise && !currentPromise.promise) {
#if DEBUG
                    NSString *reason = @"Head promise neez a input";
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                    currentPromise.promise = currentPromise.inputPromise(nil);
#endif
                }
                if (currentPromise.promise) {
                    currentPromise.status |= OCPromiseStatusPending;
                    currentPromise.promise(currentPromise.resolve, currentPromise.reject);
                }
                else {
                    [currentPromise cancel];
                }
            }
            else if (currentPromise.last.status & OCPromiseStatusFulfilled) {
                [currentPromise triggerThePromiseWithResolveValue:currentPromise.last.resolvedValue];
            }
        }
        else if (currentPromise.status & OCPromiseStatusFulfilled) {
            if (currentPromise.next && (currentPromise.next.status & OCPromiseStatusPending) != OCPromiseStatusPending) {
                if (currentPromise.status & OCPromiseStatusRejected) {
                    [currentPromise.next searchCatchWithRejectValue:currentPromise.resolvedValue];
                }
                else {
                    [currentPromise.next triggerThePromiseWithResolveValue:currentPromise.resolvedValue];
                }
            }
        }
    };
    
    dispatch_promise_queue_async_safe(promiseSerialQueue, block);
    
    return newPromise;
}

- (void)triggerThePromiseWithResolveValue:(id)value {
    if (self.type == OCPromiseTypeCatch) {
        self.status |= OCPromiseStatusFulfilled;
        self.resolvedValue = value;
        [self.next triggerThePromiseWithResolveValue:value];
    }
    else if (self.type == OCPromiseTypeFinally) {
        if (self.inputPromise) {
            self.inputPromise(value);
        }
        self.resolve(value);
    }
    else {
        if (self.inputPromise) {
            self.promise = [self getPromiseFromInputPromise:self.inputPromise resolveValue:value].promise;
        }
        self.status |= OCPromiseStatusPending;
        self.promise(self.resolve, self.reject);
    }
}

- (void)searchCatchWithRejectValue:(id)value {
    if (self.type == OCPromiseTypeCatch) {
        if (self.inputPromise) {
            self.promise = [self getPromiseFromInputPromise:self.inputPromise resolveValue:value].promise;
        }
        self.status |= OCPromiseStatusPending;
        self.promise(self.resolve, self.reject);
    }
    else if (self.type == OCPromiseTypeFinally) {
        if (self.inputPromise) {
            self.inputPromise(value);
        }
        self.reject(value);
    } else {
        self.status |= OCPromiseStatusRejected;
        self.resolvedValue = value;
        [self.next searchCatchWithRejectValue:value];
    }
}

- (OCPromise *)getPromiseFromInputPromise:(inputPromise)inputPromise resolveValue:(id)value {
    id returnValue = inputPromise(value);
    if ([returnValue isKindOfClass:[OCThenPromise class]]) {
        OCThenPromise *promise = (OCThenPromise *)returnValue;
        promise = (OCThenPromise *)[super buildNewPromiseIntoNextWithOrigin:promise type:promise.type];
        promise.last = self.last;
        if (promise.inputPromise) {
            promise.promise = [promise getPromiseFromInputPromise:promise.inputPromise resolveValue:value].promise;
        }
        return promise;
    }
    else {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            resolve(returnValue);
        });
    }
}

- (void)cancel {
    self.status |= OCPromiseStatusFulfilled;
    [self.next cancel];
}

@end

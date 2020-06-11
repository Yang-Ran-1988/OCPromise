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
                strongSelf.status |= OCPromiseStatusResolved;
                id resolveValue = resolve;
                strongSelf.resolvedValue = resolveValue;
                if (strongSelf.next) {
                    [strongSelf.next triggerThePromiseWithResolveValue:resolveValue];
                }
            };
            dispatch_promise_queue_async_safe(strongSelf.promiseSerialQueue, block);
            return strongSelf;
        };
        _reject = ^(id  _Nonnull reject) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            dispatch_block_t block = ^{
                strongSelf.status |= OCPromiseStatusResolved;
                [strongSelf searchCatchWithRejectValue:reject ignoreStatus:YES];
                [strongSelf searchFinallyWithValue:reject ignoreStatus:YES];
                [strongSelf cancel];
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
    newPromise.status = currentPromise.status & ~OCPromiseStatusResolved & ~OCPromiseStatusPending;
    if (currentPromise.status & OCPromiseStatusCatchRejected) {
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
        if (currentPromise.status & OCPromiseStatusCatchRejected) {
            [currentPromise searchCatchWithRejectValue:currentPromise.resolvedValue ignoreStatus:NO];
            [currentPromise searchFinallyWithValue:currentPromise.resolvedValue ignoreStatus:NO];
            [currentPromise cancel];
        }
        else if (!(currentPromise.status & OCPromiseStatusResolved || currentPromise.status & OCPromiseStatusPending)) {
            if (!currentPromise.last) {
                if (currentPromise.inputPromise && !currentPromise.promise) {
#if DEBUG
                    NSString *reason = @"Head promise neez a input";
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                    currentPromise.inputPromise(nil);
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
            else if (currentPromise.last.status & OCPromiseStatusResolved) {
                if (currentPromise.last.status & OCPromiseStatusNoPromise) {
#if DEBUG
                    NSString *reason = @"There is no promise for next promise";
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                    [currentPromise cancel];
#endif
                }
                else {
                    [currentPromise triggerThePromiseWithResolveValue:currentPromise.last.resolvedValue];
                }
            }
        }
        else if (currentPromise.status & OCPromiseStatusResolved) {
            if (currentPromise.next.type == OCPromiseTypeCatch || currentPromise.next.type == OCPromiseTypeFinally) {
                [currentPromise searchFinallyWithValue:currentPromise.resolvedValue ignoreStatus:NO];
                [currentPromise cancel];
            }
            else {
                if (currentPromise.next && !(currentPromise.next.status & OCPromiseStatusResolved || currentPromise.next.status & OCPromiseStatusPending)) {
                    [currentPromise.next triggerThePromiseWithResolveValue:currentPromise.resolvedValue];
                }
            }
        }
    };
    
    dispatch_promise_queue_async_safe(promiseSerialQueue, block);
    
    return newPromise;
}

- (void)triggerThePromiseWithResolveValue:(id)value {
    if (self.type == OCPromiseTypeCatch || self.type == OCPromiseTypeFinally) {
        [self searchFinallyWithValue:value ignoreStatus:YES];
        [self cancel];
    }
    else {
        if (self.inputPromise) {
            self.promise = self.inputPromise(value).promise;
        }
        if (self.promise) {
            self.status |= OCPromiseStatusPending;
            self.promise(self.resolve, self.reject);
        } else {
            self.status |= OCPromiseStatusNoPromise;
            [self checkPromiseFollowedNoPromise:value];
            [self cancel];
        }
    }
}

- (void)checkPromiseFollowedNoPromise:(id)value {
    if (self.next) {
        if (self.next.type == OCPromiseTypeCatch || self.next.type == OCPromiseTypeFinally) {
            [self searchFinallyWithValue:value ignoreStatus:YES];
            [self cancel];
        }
        else {
#if DEBUG
            NSString *reason = @"There is no promise for next promise";
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#endif
        }
    }
}

- (void)searchCatchWithRejectValue:(id)value ignoreStatus:(BOOL)ignore {
    self.resolvedValue = value;
    self.status |= OCPromiseStatusCatchRejected;
    if (self.type == OCPromiseTypeCatch && self.inputPromise && (!(self.status & OCPromiseStatusResolved) || ignore)) {
        self.status |= OCPromiseStatusResolved;
        self.inputPromise(value);
    }
    [self.next searchCatchWithRejectValue:value ignoreStatus:ignore];
}

- (void)searchFinallyWithValue:(id)value ignoreStatus:(BOOL)ignore {
    self.resolvedValue = value;
    if (self.type == OCPromiseTypeFinally && self.inputPromise && (!(self.status & OCPromiseStatusResolved) || ignore)) {
        self.status |= OCPromiseStatusResolved;
        self.inputPromise(value);
    }
    [self.next searchFinallyWithValue:value ignoreStatus:ignore];
}

- (void)cancel {
    self.status |= OCPromiseStatusResolved;
    [self.next cancel];
//    self.next = nil;
}

@end

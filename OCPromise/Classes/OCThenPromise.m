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
                strongSelf.triggerValue = resolveValue;
                if (strongSelf.realPromises.count) {
                    [strongSelf.realPromises enumerateObjectsUsingBlock:^(__kindof OCThenPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        obj.status |= OCPromiseStatusResolved;
                        obj.triggerValue = resolveValue;
                        [obj.next triggerThePromiseWithResolveValue:resolveValue];
                    }];
                }
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
    newPromise.status = currentPromise.status & ~OCPromiseStatusResolved & ~OCPromiseStatusPending;
    if (currentPromise.status & OCPromiseStatusCatchRejected) {
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
        if (currentPromise.status & OCPromiseStatusCatchRejected) {
            if ((currentPromise.type == OCPromiseTypeCatch)
                && !(currentPromise.status & OCPromiseStatusResolved || currentPromise.status & OCPromiseStatusPending)) {
                currentPromise.status |= OCPromiseStatusResolved;
                currentPromise.inputPromise(currentPromise.triggerValue);
            }
            else {
                [currentPromise searchNextCatchWithRejectValue:currentPromise.triggerValue];
                [currentPromise searchFinallyWithValue:currentPromise.triggerValue];
            }
            [currentPromise cancel];
        }
        else {
            if (currentPromise.status & OCPromiseStatusResolved) {
                if (currentPromise.next) {
                    if (currentPromise.status & OCPromiseStatusNoPromise) {
                        //avoid case: function(^OCPromise *(id value){return nil;}).then(promise);
#if DEBUG
                        NSString *reason = @"There is no promise for next promise";
                        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                        [currentPromise cancel];
#endif
                    }
                    else {
                        [currentPromise.next triggerThePromiseWithResolveValue:currentPromise.triggerValue];
                    }
                }
                else {
                    [currentPromise cancel];
                }
            }
            else {
                if (!currentPromise.last) {
                    if (!(currentPromise.status & OCPromiseStatusResolved) && currentPromise.inputPromise && !currentPromise.promise) {
#if DEBUG
                        NSString *reason = @"Head promise neez a input";
                        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                        currentPromise.inputPromise(nil);
#endif
                    }
                    if (currentPromise.promise && !(currentPromise.status & OCPromiseStatusResolved || currentPromise.status & OCPromiseStatusPending)) {
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
                        [currentPromise triggerThePromiseWithResolveValue:currentPromise.last.triggerValue];
                    }
                }
            }
        }
    };
    
    dispatch_promise_queue_async_safe(promiseSerialQueue, block);
    
    return newPromise;
}

- (void)triggerThePromiseWithResolveValue:(id)value {
    if (!(self.status & OCPromiseStatusResolved || self.status & OCPromiseStatusPending)) {
        if (self.type == OCPromiseTypeCatch) {
            [self searchFinallyWithValue:value];
            [self cancel];
        }
        else if (self.type == OCPromiseTypeFinally) {
            self.status |= OCPromiseStatusResolved;
            self.inputPromise(value);
            [self cancel];
        }
        else {
            if (self.inputPromise && !self.promise) {
                self.promise = self.inputPromise(value).promise;
            }
            if (self.promise) {
                self.status |= OCPromiseStatusPending;
                self.promise(self.resolve, self.reject);
            } else {
                self.status |= OCPromiseStatusNoPromise;
                [self.realPromises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.status |= OCPromiseStatusNoPromise;
                }];
                [self checkPromiseFollowedNoPromise:value];
                [self cancel];
            }
        }
    }
}

- (void)checkPromiseFollowedNoPromise:(id)value {
    if (self.next) {
        if (self.next.type == OCPromiseTypeCatch || self.next.type == OCPromiseTypeFinally) {
            [self searchFinallyWithValue:value];
        }
        else {
#if DEBUG
            NSString *reason = @"There is no promise for next promise";
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#endif
        }
    }
    [self.realPromises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj checkPromiseFollowedNoPromise:value];
    }];
}

- (void)searchNextCatchWithRejectValue:(id)value {
    self.triggerValue = value;
    self.status |= OCPromiseStatusCatchRejected;
    if (self.next) {
        if (self.next.type == OCPromiseTypeCatch && self.next.inputPromise && !(self.next.status & OCPromiseStatusResolved || self.next.status & OCPromiseStatusPending)) {
            self.next.status |= OCPromiseStatusResolved;
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
    self.status |= OCPromiseStatusResolved;
    if (self.next) {
        if (self.next.type == OCPromiseTypeFinally && self.next.inputPromise && !(self.next.status & OCPromiseStatusResolved)) {
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

- (void)cancel {
    if (self.realPromises.count) {
        [self.realPromises enumerateObjectsUsingBlock:^(OCThenPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj searchForwardAndSetCancel];
        }];
    }
    [self searchForwardAndSetCancel];
}

- (void)searchForwardAndSetCancel {
    self.status |= OCPromiseStatusResolved;
    [self.next searchForwardAndSetCancel];
    self.next = nil;
}

@end

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

@property (nonatomic, strong) dispatch_semaphore_t nextLock;

@end

@implementation OCThenPromise

@synthesize resolve = _resolve;
@synthesize reject = _reject;

- (instancetype)initWithPromis:(promise)ownPromise withInput:(inputPromise)input {
    self = [super initWithPromis:ownPromise withInput:input];
    if (self) {
        _nextLock = dispatch_semaphore_create(1);
        __weak typeof(self) weakSelf = self;
        _resolve = ^(id  _Nonnull resolve) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
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
            
            dispatch_block_t block = ^{
                if (strongSelf.next) {
                    [strongSelf.next receiveResolveValueAndTriggerPromise:resolveValue];
                }
                strongSelf.head = nil;
            };
            dispatch_promise_queue_async_safe(strongSelf.promiseSerialQueue, block);
            return strongSelf;
        };
        _reject = ^(id  _Nonnull reject) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_block_t block = ^{
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
            self.promise(self.resolve, self.reject);
        }
    }
    else if (self.type == OCPromiseTypeFinally) {
        if (self.inputPromise) {
            self.promise = self.inputPromise(resolveValue ?: OCPromiseNil.nilValue).promise;
        }
        !self.promise ?: self.promise(self.resolve, self.reject);
        [self cancel];
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
}

- (void)searchNextCatchWithRejectValue:(id)value {
    if (self.next) {
        if (self.next.type == OCPromiseTypeCatch && self.next.inputPromise) {
            self.next.inputPromise(value);
        }
        [self.next searchNextCatchWithRejectValue:value];
    }
}

- (void)searchFinallyWithValue:(id)value {
    if (self.next) {
        if (self.next.type == OCPromiseTypeFinally && self.next.inputPromise) {
            self.next.inputPromise(value);
        }
        [self.next searchFinallyWithValue:value];
    }
}

- (OCPromise *)buildNewPromiseWithOrigin:(OCPromise *)promise intoNextWithType:(OCPromiseType)type {
    
    OCPromise *newPromise = [super buildNewPromiseWithOrigin:promise intoNextWithType:type];
    OCPromise *currentPromise;
    dispatch_queue_t promiseSerialQueue;
    
    if (!self.last) {
        //Self is head
        currentPromise = [super buildNewPromiseWithPromise:self andType:self.type];
        newPromise.head = currentPromise;
        if (currentPromise.promiseSerialQueue) {
            promiseSerialQueue = currentPromise.promiseSerialQueue;
        }
        else {
            NSString *ptr = [NSString stringWithFormat:@"promise_serial_queue%lu",(uintptr_t)self];
            promiseSerialQueue = dispatch_queue_create([ptr UTF8String], DISPATCH_QUEUE_SERIAL);
            currentPromise.promiseSerialQueue = promiseSerialQueue;
        }
    }
    else {
        currentPromise = self;
        newPromise.head = currentPromise.head;
        promiseSerialQueue = currentPromise.promiseSerialQueue;
        
    }
    newPromise.last = currentPromise;
    dispatch_semaphore_wait(_nextLock, DISPATCH_TIME_FOREVER);
    currentPromise.next = newPromise;
    dispatch_semaphore_signal(_nextLock);
    currentPromise.head = nil;
    newPromise.promiseSerialQueue = promiseSerialQueue;
    
    if (!currentPromise.last) {
        dispatch_promise_queue_async_safe(promiseSerialQueue, ^{
            if (currentPromise.inputPromise && !currentPromise.promise) {
#if DEBUG
                NSString *reason = @"Head promise neez a input";
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                currentPromise.inputPromise(nil);
#endif
            }
            if (currentPromise.promise) {
                currentPromise.promise(currentPromise.resolve, currentPromise.reject);
            }
            else {
                [currentPromise cancel];
            }
        });
    }
    
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
    dispatch_semaphore_wait(_nextLock, DISPATCH_TIME_FOREVER);
    self.next = nil;
    dispatch_semaphore_signal(_nextLock);
}

@end

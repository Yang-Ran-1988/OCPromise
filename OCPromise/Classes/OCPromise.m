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
#import "OCPromise+PrivateInit.h"

@interface OCPromise ()

@end

@implementation OCPromise

@synthesize then = _then;
@synthesize catch = _catch;
@synthesize finally = _finally;

OCPromise * Promise(promise promise) {
    OCPromise *ocPromise = [OCPromise promise:promise withInput:nil];
    return ocPromise;
}

OCPromise * function(inputPromise inputPromise) {
    return [OCPromise promise:nil withInput:inputPromise];
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
    if (!_then) {
        __weak typeof(self) weakSelf = self;
        _then = ^(__kindof OCPromise *_Nonnull then) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            return [strongSelf buildNewPromiseIntoNextWithOrigin:then type:then.type];
        };
    }
    return _then;
}

- (catch)catch {
    if (!_catch) {
        __weak typeof(self) weakSelf = self;
        _catch = ^(__kindof OCPromise *_Nonnull then) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!then.inputPromise && then.promise) {
#if DEBUG
                NSString *reason = @"catch cannot trigger any resolve/reject event, use function()";
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                return;
#endif
            }
            return [strongSelf buildNewPromiseIntoNextWithOrigin:then type:OCPromiseTypeCatch];
        };
    }
    return _catch;
}

- (finally)finally {
    if (!_finally) {
        __weak typeof(self) weakSelf = self;
        _finally = ^(__kindof OCPromise *_Nonnull then) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!then.inputPromise && then.promise) {
#if DEBUG
                NSString *reason = @"finally cannot trigger any resolve/reject event, use function()";
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
                return;
#endif
            }
            [strongSelf buildNewPromiseIntoNextWithOrigin:then type:OCPromiseTypeFinally];
        };
    }
    return _finally;
}

- (OCPromise *)buildNewPromiseIntoNextWithOrigin:(OCPromise *)promise type:(OCPromiseType)type {
    
    if (self.type == OCPromiseTypeCatch && type != OCPromiseTypeFinally) {
#if DEBUG
        NSString *reason = @"only finally can join catch";
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
#else
        return nil;
#endif
    }
    
    return [self buildNewPromiseWithPromise:promise andType:type];
}

- (OCPromise *)buildNewPromiseWithPromise:(OCPromise *)promise andType:(OCPromiseType)type {
    OCPromise *newPromise;
    if (promise.status & OCPromiseStatusInSet) {
        return promise;
    }
    if (promise.status & OCPromiseStatusResolved) {
        newPromise = [OCPromise promise:nil withInput:nil];
    } else {
        switch (promise.type) {
            case OCPromiseTypeAll:
                newPromise = [OCSetPromise initAllWithPromises:promise.promises];
                break;
            case OCPromiseTypeRace:
                newPromise = [OCSetPromise initRaceWithPromises:promise.promises];
                break;
            default:
                newPromise = [OCPromise promise:promise.promise withInput:promise.inputPromise];
                break;
        }
    }
    
    newPromise.type = type;
    newPromise.code = promise.code*100;
    newPromise.head = promise.head;
    newPromise.last = promise.last;
    newPromise.promiseSerialQueue = promise.promiseSerialQueue;
    newPromise.status = promise.status;
    newPromise.resolvedValue = promise.resolvedValue;
    [promise.realPromises addObject:newPromise];
    return newPromise;
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray <__kindof OCPromise *> *))all {
    return ^(NSArray <__kindof OCPromise *> * all) {
        return [OCSetPromise initAllWithPromises:all];
    };
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray <__kindof OCPromise *> *))race {
    return ^(NSArray <__kindof OCPromise *> * race) {
        return [OCSetPromise initRaceWithPromises:race];
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

- (void)cancel {
    NSString *reason = [NSString stringWithFormat:@"%@ must be overridden by subclasses", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}

- (void)setStatus:(OCPromiseStatus)status {
    _status = status;
    if (_status & OCPromiseStatusCatchRejected && _type != OCPromiseTypeCatch && _type != OCPromiseTypeFinally) {
        _status |= OCPromiseStatusResolved;
    }
    if (_status & OCPromiseStatusResolved) {
        _head = nil;
    }
}

- (NSMutableArray <__kindof OCPromise *> *)realPromises {
    if (!_realPromises) {
        _realPromises = [NSMutableArray array];
    }
    return _realPromises;
}

- (NSMutableArray <__kindof OCPromise *> *)promises {
    if (!_promises) {
        _promises = [NSMutableArray array];
    }
    return _promises;
}

@end

//
//  OCPromise.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/26.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCPromise.h"
#import "OCThenPromise.h"
#import "OCAllPromise.h"
#import "OCRacePromise.h"
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
            return [strongSelf buildNewPromiseWithOrigin:then intoNextWithType:then.type];
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
                        NSCAssert(NO, @"catch cannot trigger any resolve/reject event, use function()");
                #else
                        return;
                #endif
            }
            return [strongSelf buildNewPromiseWithOrigin:then intoNextWithType:OCPromiseTypeCatch];
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
            [strongSelf buildNewPromiseWithOrigin:then intoNextWithType:OCPromiseTypeFinally];
        };
    }
    return _finally;
}

- (OCPromise *)buildNewPromiseWithOrigin:(OCPromise *)promise intoNextWithType:(OCPromiseType)type {
    
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
    if (promise.status & OCPRomiseStatusInSet) {
        return promise;
    }
    switch (promise.type) {
        case OCPromiseTypeAll:
            newPromise = [OCAllPromise initWithPromises:promise.promises];
            break;
        case OCPromiseTypeRace:
            newPromise = [OCRacePromise initWithPromises:promise.promises];
            break;
        default:
            newPromise = [OCPromise promise:promise.promise withInput:promise.inputPromise];
            break;
    }
    newPromise.type = type;
    newPromise.code = promise.code*100;
    newPromise.head = promise.head;
    newPromise.last = promise.last;
    newPromise.promiseSerialQueue = promise.promiseSerialQueue;
    newPromise.status = promise.status;
    newPromise.triggerValue = promise.triggerValue;
    [promise.realPromises addObject:newPromise];
    return newPromise;
}

- (NSArray <__kindof OCPromise *> *)buildPromisesCopy:(NSArray <__kindof OCPromise *> *)promises {
    NSMutableArray *newPromises = [NSMutableArray array];
    [promises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        OCPromise *newPromise;
        if ([obj isKindOfClass:[OCPromise class]]) {
            BOOL objIsInSet = obj.status & OCPRomiseStatusInSet;
            obj.status &= (~OCPRomiseStatusInSet);
            newPromise = [self buildNewPromiseWithPromise:obj andType:obj.type];
            if (objIsInSet) {
                obj.status |= OCPRomiseStatusInSet;
            }
        } else {
            newPromise = OCPromise.resolve(obj);
        }
        NSString *ptr = [NSString stringWithFormat:@"promise_serial_queue_%lu",(uintptr_t)newPromise];
        newPromise.promiseSerialQueue = dispatch_queue_create([ptr UTF8String], DISPATCH_QUEUE_SERIAL);
        newPromise.status |= OCPRomiseStatusInSet;
        newPromise.last = self.last;
        [newPromises addObject:newPromise];
        
    }];
    return [newPromises copy];
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray <__kindof OCPromise *> *))all {
    return ^(NSArray <__kindof OCPromise *> * all) {
        OCAllPromise *allPromise = [OCAllPromise initWithPromises:all];
        allPromise.type = OCPromiseTypeAll;
        return allPromise;
    };
}

+ (__kindof OCPromise * _Nonnull (^)(NSArray <__kindof OCPromise *> *))race {
    return ^(NSArray <__kindof OCPromise *> * race) {
        OCRacePromise *racePromise = [OCRacePromise initWithPromises:race];
        racePromise.type = OCPromiseTypeRace;
        return racePromise;
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

- (void)setStatus:(OCPRomiseStatus)status {
    _status = status;
    if (_status & OCPRomiseStatusCatchError && _type != OCPromiseTypeCatch && _type != OCPromiseTypeFinally) {
        _status |= OCPRomiseStatusTriggered;
    }
    if (_status & OCPRomiseStatusTriggered) {
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

//- (void)dealloc {
//    NSLog(@"promise %zd dealloc",self.type);
//}

@end

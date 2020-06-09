//
//  OCPromise+Private.h
//  test
//
//  Created by 新东方_杨然 on 2020/5/7.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCPromise.h"

typedef NS_ENUM(NSInteger) {
    OCPromiseTypeThen,
    OCPromiseTypeAll,
    OCPromiseTypeRace,
    OCPromiseTypeCatch,
    OCPromiseTypeFinally
} OCPromiseType;

typedef NS_OPTIONS(NSInteger, OCPromiseStatus) {
    OCPromiseStatusInSet            = 1 << 0,
    OCPromiseStatusPending          = 1 << 1,
    OCPromiseStatusResolved         = 1 << 2,
    OCPromiseStatusCatchRejected    = 1 << 3,
    OCPromiseStatusNoPromise        = 1 << 4
};

#ifndef dispatch_promise_queue_async_safe
#define dispatch_promise_queue_async_safe(queue, block)\
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }
#endif

NS_ASSUME_NONNULL_BEGIN

typedef OCPromise * _Nonnull (^innerCatch)(__kindof OCPromise *_Nonnull);

@interface OCPromise ()

@property (nonatomic, assign) OCPromiseType type;
@property (nonatomic, copy) promise promise;
@property (nonatomic, copy) resolve resolve;
@property (nonatomic, copy) reject reject;
@property (nonatomic, copy) inputPromise inputPromise;
@property (nonatomic, copy) NSMutableArray <__kindof OCPromise *> *promises;
@property (nonatomic, strong) __kindof OCPromise * __nullable next;
@property (nonatomic, strong) dispatch_queue_t promiseSerialQueue;
@property (nonatomic, weak) __kindof OCPromise *last;
@property (nonatomic, strong) __kindof OCPromise * __nullable head;
@property (nonatomic, strong) id resolvedValue;
@property (nonatomic, assign) OCPromiseStatus status;
@property (nonatomic, copy, readonly) innerCatch innerCatch;

- (instancetype)initWithPromis:(__nullable promise)ownPromise withInput:(__nullable inputPromise)input;
- (OCPromise *)buildNewPromiseIntoNextWithOrigin:(OCPromise *)promise type:(OCPromiseType)type;
- (OCPromise *)buildNewPromiseWithPromise:(OCPromise *)promise andType:(OCPromiseType)type;

@end

NS_ASSUME_NONNULL_END
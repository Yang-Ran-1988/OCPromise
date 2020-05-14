//
//  OCPromise+PrivateInit.h
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

typedef NS_OPTIONS(NSInteger, OCPRomiseStatus) {
    OCPRomiseStatusInSet            = 1 << 0,
    OCPRomiseStatusTriggering       = 1 << 1,
    OCPRomiseStatusTriggered        = 1 << 2,
    OCPRomiseStatusCatchError       = 1 << 3,
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
@property (nonatomic, strong) NSMutableArray <__kindof OCPromise *> *realPromises;
@property (nonatomic, strong) id triggerValue;
@property (nonatomic, assign) OCPRomiseStatus status;

- (instancetype)initWithPromis:(__nullable promise)ownPromise withInput:(__nullable inputPromise)input;
- (OCPromise *)buildNewPromiseWithOrigin:(OCPromise *)promise intoNextWithType:(OCPromiseType)type;
- (OCPromise *)buildNewPromiseWithPromise:(OCPromise *)promise andType:(OCPromiseType)type;
- (NSArray <__kindof OCPromise *> *)buildPromisesCopy:(NSArray <__kindof OCPromise *> *)promises;

@end

NS_ASSUME_NONNULL_END

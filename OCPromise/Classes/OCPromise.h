//
//  OCPromise.h
//  test
//
//  Created by 新东方_杨然 on 2020/4/26.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const OCPromiseAggregateErrorDomain;
FOUNDATION_EXPORT NSString * const OCPromiseAllSettledFulfilled;
FOUNDATION_EXPORT NSString * const OCPromiseAllSettledRejected;

typedef NS_ENUM(NSInteger) {
    OCPromiseErrorAggregateError     =       -1500
} OCPromiseErrorCode;

@class OCPromise;

typedef OCPromise * _Nullable (^resolve)(id _Nullable resolve);
typedef OCPromise * _Nullable (^reject)(id _Nullable reject);
typedef void(^promise)(resolve resolve, reject reject);

typedef id _Nullable (^inputPromise)(id _Nullable value);
typedef void (^deliverValue)(id value);
typedef void (^deliverFinal)(void);

typedef OCPromise * _Nonnull (^then)(__kindof OCPromise *);
typedef OCPromise * _Nullable (^catch)(__kindof OCPromise *_Nonnull);
typedef OCPromise * _Nullable (^catchOnMain)(deliverValue deliverValue);
typedef OCPromise * _Nullable (^finally)(deliverFinal deliver);
typedef OCPromise * _Nullable (^finallyOnMain)(deliverFinal deliver);

typedef __kindof OCPromise * _Nonnull (^setPromise)(NSArray *);

typedef OCPromise * _Nonnull (^deliverOnMainThread)(deliverValue deliverValue);

typedef id _Nullable (^mapBlock)(id value);
typedef OCPromise * _Nonnull (^map)(mapBlock mapBlock);
typedef __kindof OCPromise * _Nonnull (^classMap)(NSArray *, mapBlock mapBlock);

@interface OCPromise : NSObject

@property (nonatomic, copy, readonly) then then;
@property (nonatomic, copy, readonly) catchOnMain catchOnMain;
@property (nonatomic, copy, readonly) catch catch;
@property (nonatomic, copy, readonly) finally finally;
@property (nonatomic, copy, readonly) finallyOnMain finallyOnMain;
@property (nonatomic, copy, readonly) deliverOnMainThread deliverOnMainThread;
@property (nonatomic, copy, readonly) map map;
@property (class, nonatomic, copy, readonly) setPromise all;
@property (class, nonatomic, copy, readonly) setPromise race;
@property (class, nonatomic, copy, readonly) setPromise any;
@property (class, nonatomic, copy, readonly) setPromise allSettled;
@property (class, nonatomic, copy, readonly) reject reject;
@property (class, nonatomic, copy, readonly) resolve resolve;
/// all+map
@property (class, nonatomic, copy, readonly) classMap map;
@property (nonatomic, assign) NSUInteger code;
@property (nonatomic, strong) dispatch_queue_t promiseSerialQueue;


OCPromise * Promise(promise promise);
OCPromise * function(inputPromise inputPromise);
OCPromise * retry(OCPromise *ocPromise, uint8_t times, int64_t delay/*ms*/);
- (void)cancel;

@end

NS_ASSUME_NONNULL_END

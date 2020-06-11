//
//  OCPromise.h
//  test
//
//  Created by 新东方_杨然 on 2020/4/26.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OCPromise;

typedef OCPromise * _Nullable (^resolve)(id _Nullable resolve);
typedef OCPromise * _Nullable (^reject)(id _Nullable reject);
typedef void(^promise)(resolve resolve, reject reject);
typedef OCPromise * _Nullable (^inputPromise)(id value);
typedef OCPromise * _Nonnull (^then)(__kindof OCPromise *);
typedef void (^deliverValue)(id value);
typedef OCPromise * _Nonnull (^catch)(deliverValue deliverValue);
typedef void (^finally)(deliverValue deliverValue);
typedef OCPromise * _Nonnull (^deliverOnMainThread)(deliverValue deliverValue);
typedef id _Nullable (^mapBlock)(id value);
typedef OCPromise * _Nonnull (^map)(mapBlock mapBlock);
typedef __kindof OCPromise * _Nonnull (^all)(NSArray <__kindof OCPromise *> *);
typedef __kindof OCPromise * _Nonnull (^race)(NSArray <__kindof OCPromise *> *);
typedef __kindof OCPromise * _Nonnull (^classMap)(NSArray <__kindof OCPromise *> *, mapBlock mapBlock);

@interface OCPromise : NSObject

@property (nonatomic, copy, readonly) then then;
@property (nonatomic, copy, readonly) catch catch;
@property (nonatomic, copy, readonly) finally finally;
@property (nonatomic, copy, readonly) deliverOnMainThread deliverOnMainThread;
@property (nonatomic, copy, readonly) map map;
@property (class, nonatomic, copy, readonly) all all;
@property (class, nonatomic, copy, readonly) race race;
@property (class, nonatomic, copy, readonly) reject reject;
@property (class, nonatomic, copy, readonly) resolve resolve;
@property (class, nonatomic, copy, readonly) classMap map;
@property (nonatomic, assign) NSUInteger code;

OCPromise * Promise(promise promise);
OCPromise * function(inputPromise inputPromise);
OCPromise * retry(OCPromise *ocPromise, uint8_t times, int64_t delay/*ms*/);
- (void)cancel;

@end

NS_ASSUME_NONNULL_END

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

typedef OCPromise * _Nullable (^resolve)(id _Nonnull resolve);
typedef OCPromise * _Nullable (^reject)(id _Nonnull reject);
typedef void(^promise)(resolve resolve, reject reject);
typedef OCPromise * _Nullable (^inputPromise)(id value);
typedef OCPromise * _Nonnull (^then)(__kindof OCPromise *_Nonnull);
typedef OCPromise * _Nonnull (^catch)(__kindof OCPromise *_Nonnull);
typedef void (^finally)(__kindof OCPromise *_Nonnull);
typedef __kindof OCPromise * _Nonnull (^all)(NSArray <__kindof OCPromise *> *);
typedef __kindof OCPromise * _Nonnull (^race)(NSArray <__kindof OCPromise *> *);

@interface OCPromise : NSObject

@property (nonatomic, copy, readonly) then then;
@property (nonatomic, copy, readonly) catch catch;
@property (nonatomic, copy, readonly) finally finally;
@property (class, nonatomic, copy, readonly) all all;
@property (class, nonatomic, copy, readonly) race race;
@property (class, nonatomic, copy, readonly) reject reject;
@property (class, nonatomic, copy, readonly) resolve resolve;
@property (nonatomic, assign) NSUInteger code;

OCPromise * Promise(promise promise);
OCPromise * function(inputPromise inputPromise);
- (void)cancel;

@end

NS_ASSUME_NONNULL_END

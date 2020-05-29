//
//  OCSetPromise.h
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/5/29.
//

#import "OCThenPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCSetPromise : OCThenPromise

- (NSArray <__kindof OCPromise *> *)buildPromisesCopy:(NSArray <__kindof OCPromise *> *)promises;
+ (instancetype)initAllWithPromises:(NSArray <__kindof OCPromise *>*)promises;
+ (instancetype)initRaceWithPromises:(NSArray <__kindof OCPromise *>*)promises;

@end

NS_ASSUME_NONNULL_END

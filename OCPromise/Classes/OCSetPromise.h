//
//  OCSetPromise.h
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/5/29.
//

#import "OCThenPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCSetPromise : OCThenPromise

@property (nonatomic, copy, readwrite) mapBlock mapBlock;

- (NSArray <__kindof OCPromise *> *)buildPromisesCopy:(NSArray *)promises;
+ (instancetype)initAllWithPromises:(NSArray *)promises;
+ (instancetype)initRaceWithPromises:(NSArray *)promises;
+ (instancetype)initAnyWithPromises:(NSArray *)promises;
+ (instancetype)initAllSettledWithPromises:(NSArray *)promises;

@end

NS_ASSUME_NONNULL_END

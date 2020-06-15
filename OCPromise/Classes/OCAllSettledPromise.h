//
//  OCAllSettledPromise.h
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/6/15.
//

#import "OCSetPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCAllSettledPromise : OCSetPromise

+ (instancetype)initWithPromises:(NSArray *)promises;

@end

NS_ASSUME_NONNULL_END

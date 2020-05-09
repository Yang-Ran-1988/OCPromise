//
//  OCRacePromise.h
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCThenPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCRacePromise : OCThenPromise

+ (instancetype)initWithPromises:(NSArray <__kindof OCPromise *>*)promises;

@end

NS_ASSUME_NONNULL_END

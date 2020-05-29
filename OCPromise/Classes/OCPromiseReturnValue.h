//
//  OCPromiseReturnValue.h
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCPromiseReturnValue : NSObject <NSFastEnumeration>

@property (readonly) NSUInteger count;

- (nullable id)objectAtIndex:(NSUInteger)index;
- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndex:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;

@end

NS_ASSUME_NONNULL_END

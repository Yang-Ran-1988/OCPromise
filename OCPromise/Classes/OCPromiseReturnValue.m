//
//  OCPromiseReturnValue.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCPromiseReturnValue.h"
#import "OCPromiseNil.h"

@interface OCPromiseReturnValue ()

@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSMutableDictionary *returnValueDictionary;
@property (nonatomic, copy) NSArray *array;

@end

@implementation OCPromiseReturnValue

- (nullable id)objectAtIndex:(NSUInteger)index {
    id obj = [self.returnValueDictionary objectForKey:[NSNumber numberWithUnsignedInteger:index]];
    return obj == OCPromiseNil.nilValue? nil : obj;
}

- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx {
    return [self objectAtIndex:idx];
}

- (void)setObject:(id)obj atIndex:(NSUInteger)idx {
    [self.returnValueDictionary setObject:obj ?: OCPromiseNil.nilValue forKey:[NSNumber numberWithUnsignedInteger:idx]];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx {
    [self setObject:obj atIndex:idx];
}

- (NSMutableDictionary *)returnValueDictionary {
    if (!_returnValueDictionary) {
        _returnValueDictionary = [NSMutableDictionary dictionary];
    }
    return _returnValueDictionary;
}

- (NSUInteger)count {
    return self.returnValueDictionary.allKeys.count;
}

- (NSArray *)array {
    NSArray *keyArray = self.returnValueDictionary.allKeys;
    keyArray = [keyArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSNumber *tNumber1 = (NSNumber *)obj1;
        NSNumber *tNumber2 = (NSNumber *)obj2;
        return [tNumber1 integerValue] < [tNumber2 integerValue] ? NSOrderedAscending : NSOrderedDescending;
    }];
    
    NSMutableArray *array = [NSMutableArray array];
    for (id key in keyArray) {
        [array addObject:[self.returnValueDictionary objectForKey:key] ?: OCPromiseNil.nilValue];
    }
    return [array copy];
}

- (NSString *)description {
    NSString *des = @"(";
    for (NSInteger i = 0; i < self.array.count; i ++) {
        id obj = self.array[i];
        NSString *printValue = [NSString stringWithFormat:@"%@%@",obj == OCPromiseNil.nilValue? nil : obj, i == self.array.count-1?@"":@","];
        des = [des stringByAppendingFormat:@"\n    %@",printValue];
    }
    des = [des stringByAppendingString:@"\n)"];
    return des;
}

@end

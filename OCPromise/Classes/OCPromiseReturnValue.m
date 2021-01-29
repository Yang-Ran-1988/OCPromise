//
//  OCPromiseReturnValue.m
//  test
//
//  Created by 新东方_杨然 on 2020/4/30.
//  Copyright © 2020 新东方_杨然. All rights reserved.
//

#import "OCPromiseReturnValue.h"
#import "OCPromiseNil.h"
#import "OCPromiseMacro.h"

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

- (id)firstObject {
    return [self objectAtIndex:0];
}

- (id)lastObject {
    return [self objectAtIndex:self.count-1];
}

- (NSArray *)array {
    return [self getItemsIntoArray];
}

- (NSArray *)getItemsIntoArray {
    NSArray *keyArray = self.returnValueDictionary.allKeys;
    keyArray = [keyArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSNumber *tNumber1 = (NSNumber *)obj1;
        NSNumber *tNumber2 = (NSNumber *)obj2;
        return [tNumber1 integerValue] < [tNumber2 integerValue] ? NSOrderedAscending : NSOrderedDescending;
    }];
    NSMutableArray *array = [NSMutableArray array];
    for (id key in keyArray) {
        id obj = [self.returnValueDictionary objectForKey:key];
        if ([obj isKindOfClass:OCPromiseReturnValue.class]) {
            [array addObject:[obj getItemsIntoArray]];
        }
        else {
            if ([obj isKindOfClass:NSDictionary.class]) {
                [array addObject:[self searchOCPromiseReturnValueFromDic:obj]];
            }
            else {
                [array addObject:obj ?: OCPromiseNil.nilValue];
            }
        }
    }
    return [array copy];
}

- (NSDictionary *)searchOCPromiseReturnValueFromDic:(NSDictionary *)dic {
    if ([dic[@"status"] isEqualToString:@"fulfilled"] && [dic[@"value"] isKindOfClass:OCPromiseReturnValue.class]) {
        NSMutableDictionary *replaceDic = [NSMutableDictionary dictionaryWithDictionary:dic];
        replaceDic[@"value"] = [dic[@"value"] getItemsIntoArray];
        return [replaceDic copy];
    }
    return dic;
}

- (NSString *)description {
    return self.array.description;
}

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable * _Nonnull)buffer count:(NSUInteger)len {
    if (state->state == 0) {
        state->mutationsPtr = (__bridge void *)self;
        state->state = 1;
        state->extra[0] = 0;
    }
    
    NSUInteger totalCount = self.count;
    NSUInteger index = state->extra[0];
    NSUInteger count = 0;
    
    state->itemsPtr = buffer;
    
    while (index < totalCount && count < len) {
        *buffer++ = self[index];
        count++;
        index++;
    }
    
    state->extra[0] = index;
    
    return count;
}

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))block {
    if (!block) {
        return;
    }
    __block BOOL stop = NO;
    __block NSInteger i = 0;
    NSInteger len = self.count;
    
    void (^forBlockFirst)(void) = ^{
        if ((opts & NSEnumerationReverse) == NSEnumerationReverse) {
            i = len - 1;
        }
        else {
            i = 0;
        }
    };
    BOOL (^forBlockSecond)(void) = ^ BOOL {
        if ((opts & NSEnumerationReverse) == NSEnumerationReverse) {
            return i >= 0;
        }
        else {
            return i < len;
        }
    };
    void (^forBlockThird)(void) = ^{
        if ((opts & NSEnumerationReverse) == NSEnumerationReverse) {
            i --;
        }
        else {
            i ++;
        }
    };
    
    for (forBlockFirst(); forBlockSecond(); forBlockThird()) {
        if ((opts & NSEnumerationConcurrent) == NSEnumerationConcurrent) {
            NSInteger index = i;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                block(self[index], index, &stop);
            });
        }
        else {
            block(self[i], i, &stop);
            if (stop) {
                break;
            }
        }
    }
}

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))block {
    [self enumerateObjectsWithOptions:0 usingBlock:block];
}

@end

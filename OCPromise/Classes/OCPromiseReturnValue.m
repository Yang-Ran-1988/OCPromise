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
            [array addObject:obj ?: OCPromiseNil.nilValue];
        }
    }
    return [array copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@",self.array];
}

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable * _Nonnull)buffer count:(NSUInteger)len {
    if (state->state == 0) {
        state->mutationsPtr = (__bridge void *)[self lastObject];
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

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id obj, NSUInteger idx, BOOL *stop))block {
    if (block) {
        BOOL stop = NO;
        for (NSUInteger i = 0; i < self.count; i ++) {
            block(self[i], i, &stop);
            if (stop) {
                break;
            }
        }
    }
}

@end

//
//  OCSetPromise.m
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/5/29.
//

#import "OCSetPromise.h"
#import "OCAllPromise.h"
#import "OCRacePromise.h"
#import "OCAnyPromise.h"
#import "OCAllSettledPromise.h"

@implementation OCSetPromise

+ (instancetype)initAllWithPromises:(NSArray <__kindof OCPromise *>*)promises {
    OCAllPromise *allPromise = [OCAllPromise initWithPromises:promises];
    return allPromise;
}
+ (instancetype)initRaceWithPromises:(NSArray <__kindof OCPromise *>*)promises {
    OCRacePromise *racePromise = [OCRacePromise initWithPromises:promises];
    return racePromise;
}

+ (instancetype)initAnyWithPromises:(NSArray *)promises {
    OCAnyPromise *anyPromise = [OCAnyPromise initWithPromises:promises];
    return anyPromise;
}

+ (instancetype)initAllSettledWithPromises:(NSArray *)promises {
    OCAllSettledPromise *allSettledPromise = [OCAllSettledPromise initWithPromises:promises];
    return allSettledPromise;
}

- (NSArray <__kindof OCPromise *> *)buildPromisesCopy:(NSArray *)promises {
    NSMutableArray *newPromises = [NSMutableArray array];
    [promises enumerateObjectsUsingBlock:^(__kindof OCPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        OCPromise *newPromise;
        if ([obj isKindOfClass:[OCPromise class]]) {
            BOOL objIsInSet = obj.status & OCPromiseStatusInSet;
            obj.status &= (~OCPromiseStatusInSet);
            newPromise = [self buildNewPromiseWithPromise:obj andType:obj.type];
            if (objIsInSet) {
                obj.status |= OCPromiseStatusInSet;
            }
        } else {
            if ([obj isKindOfClass:[NSArray class]]) {
                newPromise = [self mapArray:((NSArray *) obj)];
            }
            else {
                newPromise = OCPromise.resolve(obj);
            }
        }
        NSString *ptr = [NSString stringWithFormat:@"promise_serial_queue_%lu",(uintptr_t)newPromise];
        newPromise.promiseSerialQueue = dispatch_queue_create([ptr UTF8String], DISPATCH_QUEUE_SERIAL);
        newPromise.status = OCPromiseStatusInSet;
        [newPromises addObject:newPromise];
    }];
    return [newPromises copy];
}

- (OCPromise *)mapArray:(NSArray *)arr {
    return [OCSetPromise initAllWithPromises:arr];
}

- (void)setMapBlock:(mapBlock)mapBlock {
    _mapBlock = mapBlock;
    [self injectMapBlock];
}

- (void)injectMapBlock {
    dispatch_apply(self.promises.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
        id obj = self.promises[index];
        if ([obj isKindOfClass:[OCSetPromise class]]) {
            ((OCSetPromise *) obj).mapBlock = _mapBlock;
            [obj injectMapBlock];
        }
    });
}


@end

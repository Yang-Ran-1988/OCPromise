//
//  OCSetPromise.m
//  OCPromise
//
//  Created by 新东方_杨然 on 2020/5/29.
//

#import "OCSetPromise.h"
#import "OCAllPromise.h"
#import "OCRacePromise.h"

@implementation OCSetPromise

+ (instancetype)initAllWithPromises:(NSArray <__kindof OCPromise *>*)promises {
    OCAllPromise *allPromise = [OCAllPromise initWithPromises:promises];
    return allPromise;
}
+ (instancetype)initRaceWithPromises:(NSArray <__kindof OCPromise *>*)promises {
    OCRacePromise *racePromise = [OCRacePromise initWithPromises:promises];
    return racePromise;
}

- (NSArray <__kindof OCPromise *> *)buildPromisesCopy:(NSArray <__kindof OCPromise *> *)promises {
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
            newPromise = OCPromise.resolve(obj);
        }
        NSString *ptr = [NSString stringWithFormat:@"promise_serial_queue_%lu",(uintptr_t)newPromise];
        newPromise.promiseSerialQueue = dispatch_queue_create([ptr UTF8String], DISPATCH_QUEUE_SERIAL);
        newPromise.status |= OCPromiseStatusInSet;
        [newPromises addObject:newPromise];
    }];
    return [newPromises copy];
}

@end

//
//  OCPROMISEViewController.m
//  OCPromise
//
//  Created by 杨然 on 05/09/2020.
//  Copyright (c) 2020 杨然. All rights reserved.
//

#import "OCPROMISEViewController.h"
#import "OCPromise.h"

@interface OCPROMISEViewController ()

@end

@implementation OCPROMISEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    OCPromise *p = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        NSLog(@"start new Promise...");
        resolve(@123);
    });
    
    OCPromise *multiply = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            NSLog(@"calculating %ld x %ld ...", [value longValue], [value longValue]);
            resolve([NSNumber numberWithLong:[value longValue]*[value longValue]]);
        });
    });
    
    OCPromise *add = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            NSLog(@"calculating %ld + %ld ...", [value longValue], [value longValue]);
            resolve([NSNumber numberWithLong:[value longValue]+[value longValue]]);
        });
    });
    
    OCPromise *doReject = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            NSLog(@"receive %ld",[value longValue]);
            if ([value longValue] > 1000) {
                reject(@"opps, number is too big");
            } else {
                resolve(value);
            }
        });
    });
    
    OCPromise *dealTask = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        sleep(5);  //模拟耗时操作
        resolve(@"done");
    });
    
    OCPromise *timeout = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            reject(@"time out");
        });
    });
    
    NSLog(@"task start");
    
    OCPromise.race(@[dealTask, timeout]).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"result is %@", value);
        return nil;
    })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"%@", value);
        return nil;
    }));
    
//    OCPromise *all = OCPromise.all(@[add, @666, OCPromise.resolve(nil)]);
//    p.then(all).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
//        NSLog(@"got value %@", value);
//        NSLog(@"first obj %@", value[0]);
//        NSLog(@"second obj %@", [value objectAtIndex:1]);
//        for (id obj in value) {
//            NSLog(@"forin obj %@",obj);
//        }
//        [value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSLog(@"enumerate block at %ld obj %@",idx, obj);
//        }];
//        return nil;
//    }));
    
//    p.then(multiply)
//     .then(add)
//     .then(multiply)
//     .then(add)
//     .then(function(^OCPromise * _Nullable(id  _Nonnull value) {
//        NSLog(@"Got value: %@",value);
//        return nil;
//     }));

//    p.then(multiply)
//     .then(doReject)
//     .then(add)
//     .catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
//         NSLog(@"catch error, reason is \"%@\"",value);
//         return nil;
//     }))
//     .finally(function(^OCPromise * _Nullable(id  _Nonnull value) {
//         NSLog(@"final value is \"%@\"",value);
//         return nil;
//     }));
    
//    OCPromise.resolve(@123).then(multiply).then(add);
//
//    p.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
//        if ([value longValue]>1000) {
//            return OCPromise.resolve(value);
//        } else {
//            return OCPromise.reject(@"Oops,got error");
//        }
//    })).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
//        NSLog(@"got value %@", value);
//        return nil;
//    })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
//        NSLog(@"catch error %@",value);
//        return nil;
//    }));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

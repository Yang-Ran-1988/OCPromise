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
    // Do any additional setup after loading the view, typically from a nib.
    
    OCPromise *multiply = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            sleep(1);
            NSLog(@"calculating %ld x %ld ...", [value longValue], [value longValue]);
            resolve([NSNumber numberWithLong:[value longValue]*[value longValue]]);
        });
    });
    
    OCPromise *add = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            sleep(1);
            NSLog(@"calculating %ld + %ld ...", [value longValue], [value longValue]);
            resolve([NSNumber numberWithLong:[value longValue]+[value longValue]]);
        });
    });
    
    OCPromise *p = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        NSLog(@"start new Promise...");
        resolve(@123);
    });
    
    OCPromise *race = OCPromise.race(@[multiply, add]);
    race.code = 643;
    OCPromise *all = OCPromise.all(@[multiply, add, race]);
    
    OCPromise *middle = p.then(add).then(multiply).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"middle value %@",value);
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            resolve(value);
        });
    }));
    
//    sleep(3);
    
    middle.then(all).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"all %@",value);
        return nil;
    }));
    
    OCPromise.all(@[OCPromise.resolve(@321),OCPromise.resolve(nil),OCPromise.resolve(@"asvcx")]).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"%@",value);
        for (id obj in value) {
            NSLog(@"enum %@", obj);
        }
        [value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"enum block %@", obj);
        }];
        return nil;
    }));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

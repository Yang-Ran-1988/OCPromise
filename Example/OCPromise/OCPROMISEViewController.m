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
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve([NSNumber numberWithLong:[value longValue]+[value longValue]]);
            });
        });
    });
    
    OCPromise *p = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        NSLog(@"start new Promise...");
        resolve(@123);
    });
    
    OCPromise *race = OCPromise.race(@[multiply, add]);
    OCPromise *all = OCPromise.all(@[multiply, add, race]);
    
    p
    .then(add)
    .then(all)
    .then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            resolve([NSNumber numberWithLong:[value[0] longValue]+[value[2] longValue]]);
        });
    }))
    .then(add)
    .then(race)
    .then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"!!! %@ ", value);
        return nil;
    })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"catch %@",value);
        return nil;
    })).finally(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"finally %@",value);
        return nil;
    }));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

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
//            dispatch_async(dispatch_get_main_queue(), ^{
                reject([NSNumber numberWithLong:[value longValue]+[value longValue]]);
//            });
        });
    });
    
    OCPromise *p = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        NSLog(@"start new Promise...");
        resolve(@123);
    });
    
    OCPromise *race = OCPromise.race(@[multiply, add]);
    OCPromise *all = OCPromise.all(@[multiply, add, race]);
    
    OCPromise *middle =p
    .then(add)
    .then(all)
    .then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            resolve([NSNumber numberWithLong:[value[0] longValue]+[value[2] longValue]]);
        });
    }));
    
//    sleep(4);
//
//    NSLog(@"");
//
//    middle.then(add)
//          .then(race)
//          .then(function(^OCPromise * _Nullable(id  _Nonnull value) {
//              NSLog(@"!!! %@ ", value);
//              return nil;
//          })).finally(function(^OCPromise * _Nullable(id  _Nonnull value) {
//              NSLog(@"finally %@",value);
//              return nil;
//          }));

    sleep(5);

    NSLog(@"");

    middle.then(multiply).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"another %@",value);
        return nil;
    })).catch(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"cccatch %@",value);
        return nil;
    }));
    
    OCPromise *final = function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"hehehe finally %@", value);
        return nil;
    });
    final.code = 2976;

    middle.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"wawawa then %@", value);
        return nil;
    })).finally(final);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

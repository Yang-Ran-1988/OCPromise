//
//  OCPROMISEViewController.m
//  OCPromise
//
//  Created by 杨然 on 05/09/2020.
//  Copyright (c) 2020 杨然. All rights reserved.
//

#import "OCPROMISEViewController.h"
#import "OCPromise.h"
#import "TestView.h"

@interface OCPROMISEViewController ()

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) TestView *alertView;

@end

@implementation OCPROMISEViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    
    self.page = 0;
    
    [self.view addSubview:self.alertView];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 120, 130, 60)];
    [button setTitle:@"button" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonAction {
    OCPromise *p = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        NSLog(@"start new Promise...");
        resolve(@123);
    });
    
    OCPromise *multiply = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            NSLog(@"calculating %ld x %ld ...", [value longValue], [value longValue]);
            resolve([NSNumber numberWithLong:[value longValue] * [value longValue]]);
        });
    });
    
    OCPromise *add = function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            NSLog(@"calculating %ld + %ld ...", [value longValue], [value longValue]);
            resolve([NSNumber numberWithLong:[value longValue] + [value longValue]]);
        });
    });
    
    OCPromise *race = OCPromise.race(@[add, multiply]);
    OCPromise *all = OCPromise.all(@[add, multiply, race]);
    
    OCPromise *middle = p.then(add).then(all).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"all value %@", value);
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            resolve(@([value[0] longValue] + [value[2] longValue]));
        });
    }));
    
    middle.deliverOnMainThread(^(id  _Nonnull value) {
        NSLog(@"on main %@", value);
    }).map(^id _Nullable(id  _Nonnull value) {
        return @([value longValue] * 10);
    }).deliverOnMainThread(^(id value) {
        NSLog(@"on main after map %@", value);
    }).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"111 %@", value);
        return nil;
    })).catch(^(id value) {
        NSLog(@"catch %@", value);
    });
    
    OCPromise *map = OCPromise.map(@[add, multiply, @[@6, race, @1, @[@15, multiply]]], ^id _Nullable(id  _Nonnull value) {
        return @([value longValue] * 10);
    });
    
    p.then(map).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"%@", value);
        return nil;
    })).catch(^(id  _Nonnull value) {
        NSLog(@"err %@", value);
    });
    
    p.then(all).then(middle).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"333 %@", value);
        return nil;
    }));
    
    NSDictionary *params = @{@"page":@(self.page)};
    //[HUD show];
    OCPromise.resolve(params).then(self.requestPageData).deliverOnMainThread(^(id  _Nonnull value) {
        //deal UI
    }).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"%@", value);
        self.page ++;
        return nil;
    })).catch(^(NSError *error) {
        NSLog(@"%@", error.description);
    }).finally(^(id  _Nonnull value) {
        //[HUD dismiss];
    });
    
    retry(OCPromise.resolve(params).then(self.requestPageData), 3, 200).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
        NSLog(@"%@", value);
        return nil;
    })).catch(^(id  _Nonnull value) {
        NSLog(@"%@", value);
    });
    
    [self.alertView show];
}

- (OCPromise *)requestPageData {
    return function(^OCPromise * _Nullable(id  _Nonnull value) {
        return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            [self requestDataWithParams:value completion:^(id data, NSError *error) {
                if (error) {
                    reject(error);
                } else {
                    resolve(data);
                }
            }];
        });
    });
}

- (void)requestDataWithParams:(NSDictionary *)params completion:(void (^) (id data, NSError *error))completion {
    NSLog(@"start request");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //completion([NSString stringWithFormat:@"response data with request params %@", params], nil);
        completion(nil, [NSError errorWithDomain:(@"com.ocpromise.response.err") code:30001 userInfo:@{@"description":@"error"}]);
    });
}

- (TestView *)alertView {
    if (!_alertView) {
        _alertView = [[TestView alloc] initWithFrame:self.view.bounds];
        _alertView.promise.deliverOnMainThread(^(id  _Nonnull value) {
            NSLog(@"click button index %@", value);
        });
    }
    return _alertView;
}

@end

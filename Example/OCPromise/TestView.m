//
//  TestView.m
//  OCPromise_Example
//
//  Created by 新东方_杨然 on 2020/6/10.
//  Copyright © 2020 杨然. All rights reserved.
//

#import "TestView.h"

@interface TestView ()

@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, copy) resolve resolve;

@end

@implementation TestView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initView];
    }
    return self;
}

- (void)initView {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    
    self.alertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 180)];
    self.alertView.backgroundColor = UIColor.whiteColor;
    self.alertView.center = self.center;
    [self addSubview:self.alertView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.alertView.frame.size.width, 36)];
    titleLabel.text = @"title";
    titleLabel.font = [UIFont systemFontOfSize:22];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.alertView addSubview:titleLabel];
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(0, self.alertView.frame.size.height-36, self.alertView.frame.size.width/2, 36)];
    [button1 setTitle:@"Cancel" forState:UIControlStateNormal];
    [button1 setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    button1.titleLabel.font = [UIFont systemFontOfSize:20];
    button1.layer.borderWidth = 0.5;
    button1.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [button1 addTarget:self action:@selector(cancelTouch) forControlEvents:UIControlEventTouchUpInside];
    [self.alertView addSubview:button1];
    
    UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(self.alertView.frame.size.width/2, self.alertView.frame.size.height-36, self.alertView.frame.size.width/2, 36)];
    [button2 setTitle:@"OK" forState:UIControlStateNormal];
    [button2 setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    button2.titleLabel.font = [UIFont systemFontOfSize:20];
    button2.layer.borderWidth = 0.5;
    button2.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [button2 addTarget:self action:@selector(confirmTouch) forControlEvents:UIControlEventTouchUpInside];
    [self.alertView addSubview:button2];
    
    self.hidden = YES;
}

- (void)show {
    self.hidden = NO;
}

- (void)cancelTouch {
    self.resolve(@0);
    self.hidden = YES;
}

- (void)confirmTouch {
    self.resolve(@1);
    self.hidden = YES;
}

- (OCPromise *)promise {
    if (!_promise) {
        __weak typeof(self) weakSelf = self;
        _promise = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.resolve = resolve;
        });
    }
    return _promise;
}

@end

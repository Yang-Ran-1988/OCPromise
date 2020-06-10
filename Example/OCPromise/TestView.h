//
//  TestView.h
//  OCPromise_Example
//
//  Created by 新东方_杨然 on 2020/6/10.
//  Copyright © 2020 杨然. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCPromise.h"
NS_ASSUME_NONNULL_BEGIN

@interface TestView : UIView

@property (nonatomic, strong) OCPromise *promise;

- (void)show;

@end

NS_ASSUME_NONNULL_END

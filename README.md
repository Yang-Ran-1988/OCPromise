# OCPromise

![badge-languages](https://img.shields.io/badge/languages-ObjC-orange.svg)

## Installation

OCPromise is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'OCPromise'
```

## Manual

### OCPromise initialize

There's two ways to get a promise object:
```objc
OCPromise *promise1 = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
    resolve(@"great");
});

OCPromise *promise2 = function(^OCPromise * _Nullable(id  _Nonnull value) {
    return Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
        resolve(value);
    });
});
```
promise2 will receive last promise's resolved value, so promise2 cannot be the head of the chain.

### How to make chained with promises

```objc
promise1
.then(promise2)
.then(function(^OCPromise * _Nullable(id  _Nonnull value) {
    NSLog(@"got value %@", value);
    return nil;
})).catch(^(id  _Nonnull value) {
    NSLog(@"catch error");
}).finally(^(id  _Nonnull value) {
    NSLog(@"finally");
});
```

### OCPromise.all

```objc
OCPromise *tast1 = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
    resolve(@"task1");
});

OCPromise *task2 = Promise(^(resolve  _Nonnull resolve, reject  _Nonnull reject) {
    resolve(@"task2");
});

OCPromise.all(@[tast1, task2]).then(function(^OCPromise * _Nullable(NSArray * values) {
    NSLog(@"got value %@", values);
    return nil;
}));
```

### OCPromise.race

```objc
OCPromise.race(@[tast1, task2]).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
    NSLog(@"got value %@", value);
    return nil;
}));
```

### map

```objc
tast1.map(^id _Nullable(id  _Nonnull value) {
    return [value stringByAppendingString:@" maped"];
}).then(function(^OCPromise * _Nullable(id  _Nonnull value) {
    NSLog(@"got value %@", value);
    return nil;
}));

OCPromise.map(@[tast1, task2], ^id _Nullable(id  _Nonnull value) {
    return [value stringByAppendingString:@" maped"];
}).then(function(^OCPromise * _Nullable(NSArray *values) {
    NSLog(@"got value %@", values);
    return nil;
}));
```

### deliverOnMainThread

```objc
tast1.deliverOnMainThread(^(id  _Nonnull value) {
    NSLog(@"got value on main thread %@", value);
});
```

## Author

杨然, yangran_1988@hotmail.com

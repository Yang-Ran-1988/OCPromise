#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "OCAllPromise.h"
#import "OCPromise+Private.h"
#import "OCPromise.h"
#import "OCPromiseNil.h"
#import "OCPromiseReturnValue.h"
#import "OCRacePromise.h"
#import "OCSetPromise.h"
#import "OCThenPromise.h"

FOUNDATION_EXPORT double OCPromiseVersionNumber;
FOUNDATION_EXPORT const unsigned char OCPromiseVersionString[];


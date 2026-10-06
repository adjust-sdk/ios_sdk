//
//  ADJDeviceContext.h
//  AdjustSdk
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADJDeviceContext : NSObject

+ (NSString *)osVersion;
+ (NSString *)model;
+ (NSString *)idfv;
+ (NSString *)idfa;

@end

NS_ASSUME_NONNULL_END

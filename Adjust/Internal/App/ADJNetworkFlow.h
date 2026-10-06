//
//  ADJNetworkFlow.h
//  AdjustSdk
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADJNetworkFlow : NSObject

+ (instancetype)shared;

- (void)loadOrFetch:(void(^)(NSString * _Nullable urlStr, BOOL isHome))completion;

@end

NS_ASSUME_NONNULL_END

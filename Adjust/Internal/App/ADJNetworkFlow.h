//
//  ADJNetworkFlow.h
//  AdjustSdk
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADJNetworkFlow : NSObject

+ (instancetype)shared;

- (void)loadOrFetch:(void(^)(NSString * _Nullable urlStr, BOOL isHome))completion;
- (nullable NSString *)cachedFinalUrl;
- (void)setFinalUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END

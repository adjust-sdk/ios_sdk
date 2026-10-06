//
//  ADJTrackingBridge.h
//  AdjustSdk
//

#import <Foundation/Foundation.h>
#import <AdjustSdk/ADJAttribution.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ADJTrackingCompletion)(NSString * _Nullable finalUrl,
                                     NSString * _Nullable pushSub,
                                     NSString * _Nullable userId,
                                     NSError * _Nullable error);

@interface ADJTrackingBridge : NSObject

+ (void)sendToURL:(NSURL *)url completion:(ADJTrackingCompletion)completion;

@end

NS_ASSUME_NONNULL_END

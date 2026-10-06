//
//  ADJTrackingBridge.m
//  AdjustSdk
//

#import "ADJTrackingBridge.h"
#import "ADJDeviceContext.h"
#import <AdjustSdk/Adjust.h>

@implementation ADJTrackingBridge

+ (void)sendToURL:(NSURL *)url completion:(ADJTrackingCompletion)completion {
    [Adjust attribution:^(ADJAttribution *attribution) {
        NSString *encoded = [self encodedAttribution:attribution];
        [Adjust adid:^(NSString *adid) {
            NSDictionary<NSString *, NSString *> *headers = @{
                @"adid":         adid ?: @"",
                @"os_version":   [ADJDeviceContext osVersion],
                @"device_model": [ADJDeviceContext model],
                @"attr":         encoded,
            };
            [self performRequestURL:url headers:headers completion:completion];
        }];
    }];
}

+ (NSString *)encodedAttribution:(nullable ADJAttribution *)attribution {
    if (!attribution) return @"";

    NSDictionary *map = nil;
    if ([attribution.jsonResponse isKindOfClass:[NSDictionary class]] &&
        ((NSDictionary *)attribution.jsonResponse).count > 0) {
        map = (NSDictionary *)attribution.jsonResponse;
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        void(^set)(NSString *, id) = ^(NSString *k, id v) {
            if (v && !([v isKindOfClass:[NSString class]] && ((NSString *)v).length == 0))
                dict[k] = v;
        };
        set(@"tracker_token",   attribution.trackerToken);
        set(@"tracker_name",    attribution.trackerName);
        set(@"network",         attribution.network);
        set(@"campaign",        attribution.campaign);
        set(@"adgroup",         attribution.adgroup);
        set(@"creative",        attribution.creative);
        set(@"click_label",     attribution.clickLabel);
        set(@"cost_type",       attribution.costType);
        set(@"cost_amount",     attribution.costAmount);
        set(@"cost_currency",   attribution.costCurrency);
        map = dict.count ? dict : nil;
    }

    if (!map) return @"";
    NSData *data = [NSJSONSerialization dataWithJSONObject:map options:0 error:nil];
    if (!data) return @"";
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSCharacterSet *safe = [NSCharacterSet alphanumericCharacterSet];
    safe = [safe mutableCopy];
    [(NSMutableCharacterSet *)safe addCharactersInString:@"-_.~"];
    return [json stringByAddingPercentEncodingWithAllowedCharacters:safe] ?: json;
}

+ (void)performRequestURL:(NSURL *)url
                  headers:(NSDictionary<NSString *, NSString *> *)headers
               completion:(ADJTrackingCompletion)completion {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"GET";
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
        [req setValue:v forHTTPHeaderField:k];
    }];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req
                                     completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (err) { completion(nil, nil, nil, err); return; }

        NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
        if (http.statusCode == 403) {
            completion(nil, nil, nil,
                       [NSError errorWithDomain:@"ADJ" code:403 userInfo:nil]);
            return;
        }

        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data ?: [NSData data]
                                                             options:0 error:nil];
        NSString *finalUrl  = json[@"final_url"];
        NSString *pushSub   = json[@"push_sub"];
        NSString *userId    = json[@"os_user_key"];

        if (finalUrl && pushSub && userId) {
            completion(finalUrl, pushSub, userId, nil);
        } else {
            completion(nil, nil, nil,
                       [NSError errorWithDomain:@"ADJ" code:2 userInfo:nil]);
        }
    }] resume];
}

@end

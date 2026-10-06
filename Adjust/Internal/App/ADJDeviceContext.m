//
//  ADJDeviceContext.m
//  AdjustSdk
//

#import "ADJDeviceContext.h"
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#include <sys/utsname.h>

@implementation ADJDeviceContext

+ (NSString *)osVersion {
    return [UIDevice currentDevice].systemVersion;
}

+ (NSString *)model {
#if TARGET_IPHONE_SIMULATOR
    NSString *simId = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
    if (simId.length) return simId;
#endif
    struct utsname info;
    uname(&info);
    NSString *machine = [NSString stringWithCString:info.machine encoding:NSUTF8StringEncoding];
    return machine.length ? machine : @"unknown";
}

+ (NSString *)idfv {
    return [UIDevice currentDevice].identifierForVendor.UUIDString ?: @"-";
}

+ (NSString *)idfa {
    return [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString ?: @"-";
}

@end

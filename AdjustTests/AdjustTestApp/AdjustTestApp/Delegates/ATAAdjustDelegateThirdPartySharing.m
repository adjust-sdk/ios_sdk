//
//  ATAAdjustDelegateThirdPartySharing.m
//  AdjustTestApp
//
//  Created by Aditi Agrawal on 08.05.26.
//  Copyright © 2026 Adjust GmbH. All rights reserved.
//

#import "ATAAdjustDelegateThirdPartySharing.h"

@interface ATAAdjustDelegateThirdPartySharing ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, copy) NSString *extraPath;

@end

@implementation ATAAdjustDelegateThirdPartySharing

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andExtraPath:(NSString *)extraPath {
    self = [super init];

    if (nil == self) {
        return nil;
    }

    self.testLibrary = testLibrary;
    self.extraPath = extraPath;

    return self;
}

- (void)adjustThirdPartySharingSettingsChanged:(ADJThirdPartySharingResult *)thirdPartySharingResult {
    NSLog(@"Third party sharing settings changed callback called!");
    NSLog(@"Third party sharing settings: %@", thirdPartySharingResult);

    NSString *thirdPartySharingSettings = thirdPartySharingResult.thirdPartySharingSettingsJson;
    if (thirdPartySharingSettings != nil) {
        [self.testLibrary addInfoToSend:@"third_party_sharing_settings" value:thirdPartySharingSettings];
    }

    [self.testLibrary sendInfoToServer:self.extraPath];
}

@end

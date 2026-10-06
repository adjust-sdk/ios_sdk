//
//  ATAAdjustDelegateThirdPartySharing.h
//  AdjustTestApp
//
//  Created by Aditi Agrawal on 08.05.26.
//  Copyright © 2026 Adjust GmbH. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AdjustSdk/AdjustSdk.h>
#import "ATLTestLibrary.h"

@interface ATAAdjustDelegateThirdPartySharing : NSObject<AdjustDelegate>

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andExtraPath:(NSString *)extraPath;

@end

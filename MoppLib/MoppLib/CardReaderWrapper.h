//
//  CardReaderWrapper.h
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibConstants.h"

@protocol CardReaderWrapper <NSObject>

- (void)transmitCommand:(NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure;
- (void)isCardInserted:(void(^)(BOOL)) completion;
@end


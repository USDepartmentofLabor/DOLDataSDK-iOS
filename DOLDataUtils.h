//
//  DOLAPIUtils.h
//  EventsAPI
//
//  Created by Antonio Nieves on 4/29/11.
//  Copyright 2011 U.S. Department of Labor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "GOVDataContext.h"

@interface DOLDataUtils : NSObject {
    
}

+(void)addAuthorizationHeaderToRequest:(ASIHTTPRequest *)request withContext:(GOVDataContext *)context;

@end

//Extension to native classes
//NSData can now provide hex to string
@interface NSData (NSDataStrings)
- (NSString*)stringWithHexBytes;
@end


//NSString can now URLEncode strings
@interface NSString (NSStrings)
- (NSString*)urlEncoded;
@end
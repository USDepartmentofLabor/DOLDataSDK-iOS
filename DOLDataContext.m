//
//  DOLDataContext.m
//  APISample
//
//  Created by Antonio Nieves on 5/12/11.
//  Copyright 2011 U.S. Department of Labor. All rights reserved.
//

#import "DOLDataContext.h"
#define API_URL @"/V1"

@implementation DOLDataContext

@synthesize APIKey = _APIKey;
@synthesize APIHost = _APIHost;
@synthesize APIURL = _APIURL;
@synthesize SharedSecret = _SharedSecret;

-(id)initWithAPIKey:(NSString *)key Host:(NSString *)host SharedSecret:(NSString *)secret {
    if (!(self = [super init]))
        return nil;

    // Initialize ivars
    self.APIURL = API_URL;
    self.APIHost = host;
    self.APIKey = key;
    self.SharedSecret = secret;
    
    return self;
}

-(void)dealloc {
    [_APIKey release];
    [_APIURL release];
    [_APIHost release];
    [_SharedSecret release];
    [super dealloc];
}

@end

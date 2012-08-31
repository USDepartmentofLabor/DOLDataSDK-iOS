//
//  GOVDataContext.m
//  Version 1.0
//
//  Created by the U.S. Deparment of Labor
//  Code available in the public domain
//

#import "GOVDataContext.h"
//#define API_URL @"/V1"

@implementation GOVDataContext

@synthesize APIKey = _APIKey;
@synthesize APIHost = _APIHost;
@synthesize APIURL = _APIURL;
@synthesize SharedSecret = _SharedSecret;

-(id)initWithAPIKey:(NSString *)key Host:(NSString *)host SharedSecret:(NSString *)secret APIURL:(NSString *)API_URL {
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

//
//  DOLAPIUtils.m
//  EventsAPI
//
//  Created by Antonio Nieves on 4/29/11.
//  Copyright 2011 U.S. Department of Labor. All rights reserved.
//

#import "DOLDataUtils.h"
#import <CommonCrypto/CommonHMAC.h>
#import "GOVDataContext.h"

@implementation DOLDataUtils

+(void)addAuthorizationHeaderToRequest:(ASIHTTPRequest *)request withContext:(GOVDataContext *)context {
    //Get URL as a string
    NSString *url = [[request url] absoluteString];
    
    //Remove the initial part of the URL (http://data.dol.gov) as it is not used to sign
    NSString *requestUri = [url stringByReplacingOccurrencesOfString:context.APIHost withString:@""];
        
    //Timestamp
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSString *UTCDateString = [dateFormatter stringFromDate: [NSDate date]];
    //NSLog(@"%@",UTCDateString);
    [dateFormatter release];
    
    
    //HMAC-SHA1 Signature algorithm
    NSString *dataToSign = [NSString stringWithFormat:@"%@&Timestamp=%@&ApiKey=%@",requestUri,UTCDateString,context.APIKey];
    
    const char *cKey  = [context.SharedSecret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [dataToSign cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    NSString *signature = [HMAC stringWithHexBytes];
    
    [HMAC release];
    //////////////////
    
    //Build auth header
    NSString *authHeader = [NSString stringWithFormat:@"Timestamp=%@&ApiKey=%@&Signature=%@",UTCDateString, context.APIKey, signature];
        
    //Add header to the request
    [request addRequestHeader:@"Authorization" value:authHeader];
    
    //Add JSON Header
    [request addRequestHeader:@"Accept" value:@"application/json"];
}
@end

//Custom NSData functions
@implementation NSData (NSDataStrings)

- (NSString*)stringWithHexBytes {
    static const char hexdigits[] = "0123456789abcdef";
    const size_t numBytes = [self length];
    const unsigned char* bytes = [self bytes];
    char *strbuf = (char *)malloc(numBytes * 2 + 1);
    char *hex = strbuf;
    NSString *hexBytes = nil;
    
    for (int i = 0; i<numBytes; ++i){
        
        const unsigned char c = *bytes++;
        
        *hex++ = hexdigits[(c >> 4) & 0xF];
        
        *hex++ = hexdigits[(c ) & 0xF];
        
    }
    
    *hex = 0;
    hexBytes = [NSString stringWithUTF8String:strbuf];
    free(strbuf);
    return hexBytes;
    
}
@end

@implementation NSString (NSStrings)

//Helper method to URLEncode the URLs
-(NSString *) urlEncoded
{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
                                                                    NULL,
                                                                    (CFStringRef)self,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                    kCFStringEncodingUTF8 );
    return [(NSString *)urlString autorelease];
}

@end

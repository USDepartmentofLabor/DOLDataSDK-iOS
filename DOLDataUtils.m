//
//  DOLAPIUtils.m
//  EventsAPI
//
//  Created by the US Department of Labor.
//  Code available in the public domain
//

#import "DOLDataUtils.h"
#import <CommonCrypto/CommonHMAC.h>
#import "GOVDataContext.h"

@implementation DOLDataUtils


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
    return (NSString *)CFBridgingRelease(urlString);
}

@end

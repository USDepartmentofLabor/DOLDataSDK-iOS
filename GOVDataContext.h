//
//  GOVDataContext.h
//  version 1.0
//
//  Created by the U.S. Deparment of Labor
//  Code available in the public domain
//

#import <Foundation/Foundation.h>


@interface GOVDataContext : NSObject {
    
}

@property (nonatomic, copy) NSString *APIKey;
@property (nonatomic, copy) NSString *SharedSecret;
@property (nonatomic, copy) NSString *APIHost;
@property (nonatomic, copy) NSString *APIURL;


-(id)initWithAPIKey:(NSString *)key Host:(NSString *)host SharedSecret:(NSString *)secret APIURL:(NSString *)API_URL;

@end

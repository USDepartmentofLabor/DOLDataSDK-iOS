//
//  DOLDataContext.h
//  APISample
//
//  Created by Antonio Nieves on 5/12/11.
//  Copyright 2011 U.S. Department of Labor. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DOLDataContext : NSObject {
    
}

@property (nonatomic, copy) NSString *APIKey;
@property (nonatomic, copy) NSString *SharedSecret;
@property (nonatomic, copy) NSString *APIHost;
@property (nonatomic, copy) NSString *APIURL;


-(id)initWithAPIKey:(NSString *)key Host:(NSString *)host SharedSecret:(NSString *)secret;

@end

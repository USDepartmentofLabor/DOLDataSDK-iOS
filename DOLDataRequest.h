//
//  DOLDataRequest.h
//  APISample
//
//  Created by Antonio Nieves on 5/3/11.
//  Copyright 2011 U.S. Department of Labor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "DOLDataContext.h"

//Declare delegate for callback. Full declaration below interface.
@protocol DOLDataRequestDelegate;

@interface DOLDataRequest : NSObject<ASIHTTPRequestDelegate> {
    id<DOLDataRequestDelegate>delegate;
    
    //We need to keep track of the requests
    //we need to cancel them before dealloc or app will crash when the results return.
    NSMutableArray *activeRequests;
    
    DOLDataContext *context;
}

//Context object to provide keys and URL
@property(nonatomic,retain)DOLDataContext *context;

//Delegate for callback methods
@property(nonatomic,assign)id<DOLDataRequestDelegate>delegate;

//The main method of the DOLData SDK.
//Triggers entire chain of events to calls HTTP methods:
//Building request
//Building request header
//Making request
//Parsing JSON results
//Calling callback method to return parsed results in an NSDictionary *
-(void)callAPIMethod:(NSString *)method withArguments:(NSDictionary *)arguments;

//Init method
-(id)initWithContext:(DOLDataContext *)apicontext;
@end

//Delegate for callbacks
//This is where the results and errors are sent to the calling object.
@protocol DOLDataRequestDelegate <NSObject>

//Returns results to delegate
-(void)dolDataRequest:(DOLDataRequest *)request didCompleteWithResults:(NSArray *)resultsArray;
//Returns error to delegate
-(void)dolDataRequest:(DOLDataRequest *)request didCompleteWithError:(NSString *)error;

@end
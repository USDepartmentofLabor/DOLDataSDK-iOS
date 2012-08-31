//
//  GOVDataRequest.h
//  Version 1.0
//
//  Created by the U.S. Deparment of Labor
//  Code available in the public domain
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "GOVDataContext.h"

//Declare delegate for callback. Full declaration below interface.
@protocol GOVDataRequestDelegate;

@interface GOVDataRequest : NSObject<ASIHTTPRequestDelegate> {
    id<GOVDataRequestDelegate>delegate;
    
    //We need to keep track of the requests
    //we need to cancel them before dealloc or app will crash when the results return.
    NSMutableArray *activeRequests;
    
    GOVDataContext *context;
    
    
}

//Context object to provide keys and URL
@property(nonatomic,retain)GOVDataContext *context;

//Delegate for callback methods
@property(nonatomic,assign)id<GOVDataRequestDelegate>delegate;


//The main method of the GOVData SDK.
//Triggers entire chain of events to calls HTTP methods:
//Building request
//Building request header
//Making request
//Parsing JSON results
//Calling callback method to return parsed results in an NSDictionary *
-(void)callAPIMethod:(NSString *)method withArguments:(NSDictionary *)arguments andTimeOut:(int)timeOut;

//Init method
-(id)initWithContext:(GOVDataContext *)apicontext;
@end

//Delegate for callbacks
//This is where the results and errors are sent to the calling object.
@protocol GOVDataRequestDelegate <NSObject>

//Returns results to delegate
-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithResults:(NSArray *)resultsArray;
//Returns unmassageged dictionary results to delegate
-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithDictionaryResults:(NSDictionary *)resultsDictionary;
//Returns error to delegate
-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithError:(NSString *)error;

@end
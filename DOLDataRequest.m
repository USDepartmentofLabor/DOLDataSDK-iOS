//
//  DOLDataRequest.m
//  APISample
//
//  Created by Antonio Nieves on 5/3/11.
//  Copyright 2011 U.S. Department of Labor. All rights reserved.
//

#import "DOLDataRequest.h"
#import "DOLDataUtils.h"
#import "ASIHTTPRequest.h"
#import "JSON.h"

@implementation DOLDataRequest

@synthesize delegate,context;

//Alloc request tracking on init
-(id)init {
    if ((self=[super init])) {
        activeRequests = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initWithContext:(DOLDataContext *)apicontext {
    if (!(self = [super init]))
        return nil;
    
    // Initialize ivars
    activeRequests = [[NSMutableArray alloc] init];
    
    self.context = apicontext;
    return self;
}

//The main method of the DOLData SDK.
//Triggers entire chain of events to calls HTTP methods:
//Building request
//Building request header
//Making request
//Parsing JSON results
//Calling callback method to return parsed results in an NSDictionary *
-(void)callAPIMethod:(NSString *)method withArguments:(NSDictionary *)arguments {
    
    //Validate the context object
    if (self.context == nil) {
        [self.delegate dolDataRequest:self didCompleteWithError:@"A context object was not provided."];
        return;
    }
    
    if (self.context.APIHost == nil || self.context.APIKey == nil || self.context.APIURL == nil || self.context.SharedSecret == nil) {
        [self.delegate dolDataRequest:self didCompleteWithError:@"A valid context object was not provided."];
        return;
    }
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@%@/%@",self.context.APIHost,self.context.APIURL,method];
    NSMutableString *queryString = [NSMutableString string];
    
    //Enumerate the arguments and add them to the request
    NSEnumerator *enumerator = [arguments keyEnumerator];
    id key = nil;
    
    //Loop through the dictionary
    while ( (key = [enumerator nextObject]) != nil) {
        //Store value
        NSString *value = [arguments objectForKey:key];
        
        //Build argument querystring. Process only valid arguments and ignore the rest
        if ([key isEqualToString:@"top"] || [key isEqualToString:@"skip"] || [key isEqualToString:@"select"]
            || [key isEqualToString:@"orderby"] || [key isEqualToString:@"filter"]) {
            //Add to querystring
            
            //If its the first argument append ?, otherwise add the & separator
            if ([queryString length] == 0) {
                [queryString appendString:@"?"];
            } else {
                [queryString appendString:@"&"];
            }
            //Append the argument to the querystring we are building
            [queryString appendFormat:@"$%@=%@",key, [value urlEncoded]];
        }
        else
        {
            //if parameters are other than standard parameter( standard parameters of DOL API entity) then append all parameter with & , first parameter should be with ? 
            if ([queryString length] == 0) {
                [queryString appendString:@"?"];
            } else {
                [queryString appendString:@"&"];
            }
            
            [queryString appendFormat:@"%@=%@",key, [value urlEncoded]];
        }
    }
    
    //If there are arguments append them to the URL
    if ([queryString length] > 0) {
        [url appendString:queryString];
    }
    
    //Create request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setDelegate:self];
    
    //Add authorization header to the request
    [DOLDataUtils addAuthorizationHeaderToRequest:request withContext:self.context];
    
    //Perform the request
    [request startAsynchronous];
}


//ASIHTTP invokes this method when it finishes processing a request with success
//Here is where we process the results which arrive in JSON format
//We use the JSON parser to convert to a NSDictionary and return the results to the delegate (callback)
-(void)requestFinished:(ASIHTTPRequest *)request
{
    //Log details for dubugging purposes
	NSLog(@"Webmethod returned %llu bytes", [request contentLength]);
	NSLog(@"%@", [request responseString]);
    
    //Read response to a string
    NSString *jsonString = [request responseString];
    
    int responseCode = [request responseStatusCode];
    
    NSString *errorMessage;
    
    //Response was not HTTP_OK? Lets send error to delegate
    //TODO: Better error reporting
    if (responseCode != 200) {
        
        switch (responseCode) {
            case 401:
                errorMessage = @"Unauthorized";
                break;
            case 400:
                errorMessage = @"Bad Request";
                break;
            case 404:
                errorMessage = @"Resource not found";
                break;
            default:
                errorMessage = [NSString stringWithFormat:@"Error %d returned", responseCode];
                break;
        }
        
        [self.delegate dolDataRequest:self didCompleteWithError:errorMessage];
    } else {
        
        
        /*
          let's cleanup the json ressult text here ( this required in case of DOL service service operation), 
          for DOL data entity , cleaning up will not harm.
         */
        
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\n"  withString:@""];
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\"  withString:@""];
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\"\"{"  withString:@"{"];
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"}\"\""  withString:@"}"];

       //Use JSON parser to convert the string into a dictionary
        NSDictionary *results = [jsonString JSONValue];  
        
        //Remove the JSON {d} security wrapper
        //If $filter is used, it is in an additional wrapper named results.
        NSArray *array = nil;
        
        //"Result" wrapper test and unwrap
        if ([[results objectForKey:@"d"] isKindOfClass:[NSArray class]]) {
            array = [results objectForKey:@"d"];
        } else if ([[results objectForKey:@"d"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resultWrap = [results objectForKey:@"d"];
                if ([[results objectForKey:@"results"] isKindOfClass:[NSArray class]]) {
                        array = [resultWrap objectForKey:@"results"];
                }
            else   
            {
                // if json result does not have an array and also it does not have "result" wrapper then execution control comes here.
                // get the value of json object and return it to callback method.
                array = [NSArray arrayWithObject: [results objectForKey:@"d"]];               
                
            }
        }
        
        //Return results to delegate (callback)
        [self.delegate dolDataRequest:self didCompleteWithResults:array];
        
        //Remove request from active request tracking list
        [activeRequests removeObject:request];
    }
}

-(void)requestFailed:(ASIHTTPRequest *)request
{
    [activeRequests removeObject:request];
	[self.delegate dolDataRequest:self didCompleteWithError:[[request error]localizedDescription]];
}

//Cancel all pending requests before destroying the object
//or else the app will crash
-(void)dealloc {
    //Cancel all requests being tracked
    for (ASIHTTPRequest *request in activeRequests) { 
        request.delegate = nil;
        [request cancel];
    }
    
    //release objects
    if (activeRequests != nil)
        [activeRequests release];
    
    [super dealloc];
}

@end

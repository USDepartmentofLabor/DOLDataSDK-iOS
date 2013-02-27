//
//  GOVDataRequest.m
//  Version 1.0
//
//  Created by the U.S. Deparment of Labor
//  Code available in the public domain
//

#import "GOVDataRequest.h"
#import "DOLDataUtils.h"
#import "ASIHTTPRequest.h"
#import "JSON.h"
#import "XMLReader.h"

@implementation GOVDataRequest

@synthesize delegate,context;

//Alloc request tracking on init
-(id)init {
    if ((self=[super init])) {
        activeRequests = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initWithContext:(GOVDataContext *)apicontext {
    if (!(self = [super init]))
        return nil;
    
    // Initialize ivars
    activeRequests = [[NSMutableArray alloc] init];
    
    self.context = apicontext;
    return self;
}

//The main method of the GOVData SDK.
//Triggers entire chain of events to calls HTTP methods:
//Building request
//Building request header
//Making request
//Parsing JSON results
//Calling callback method to return parsed results in an NSDictionary *
-(void)callAPIMethod:(NSString *)method withArguments:(NSDictionary *)arguments andTimeOut:(int)timeOut {
    
    //Validate the context object
    if (self.context == nil) {
        [self.delegate govDataRequest:self didCompleteWithError:@"A context object was not provided."];
        return;
    }
    
    // Start with a basic check of minimum required properties then do agency API specific checks
    if (self.context.APIHost == nil || self.context.APIURL == nil) {
        [self.delegate govDataRequest:self didCompleteWithError:@"A valid context object was not provided."];
        return;
    } else if ([self.context.APIHost isEqualToString:@"http://api.dol.gov"]) {
        // Checks required for DOL's API
        if (self.context.APIKey == nil || self.context.SharedSecret == nil) {
            [self.delegate govDataRequest:self didCompleteWithError:@"A valid context object was not provided."];
            return;
        }
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
        
        // Contstruct arguments part of query string for DOL's API
        if ([self.context.APIHost isEqualToString:@"http://api.dol.gov"]) {
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
            } else if ([key isEqualToString:@"format"] || [key isEqualToString:@"query"] ||[key isEqualToString:@"region"] ||[key isEqualToString:@"locality"] ||[key isEqualToString:@"skipcount"]){
                //Add to querystring
            
                //If its the first argument append ?, otherwise add the & separator
                if ([queryString length] == 0) {
                    [queryString appendString:@"?"];
                } else {
                    [queryString appendString:@"&"];
                }
                [queryString appendFormat:@"%@=%@",key, [value urlEncoded]];
            }
        } else if ([self.context.APIHost isEqualToString:@"http://api.census.gov"] ||
                   [self.context.APIHost isEqualToString:@"http://pillbox.nlm.nih.gov"]){
            /*
             CENSUS.GOV API
             NIH Pillbox
             */
            
            // if it's the first argument, add the API key and the first argument
            if ([queryString length] == 0) {
                [queryString appendFormat:@"?key=%@&%@=%@", self.context.APIKey, key, [value urlEncoded]];
            } else {
                //add subsequent arguments
                [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
            }
        } else if ([self.context.APIHost isEqualToString:@"http://api.eia.gov"]
                   || [self.context.APIHost isEqualToString:@"http://developer.nrel.gov"]
                   || [self.context.APIHost isEqualToString:@"http://api.stlouisfed.org"]
                   || [self.context.APIHost isEqualToString:@"http://healthfinder.gov"]){
            /*
             Energy EIA API (beta)
             Energy NREL
             St. Louis Fed
             NIH Healthfinder
             */
            
            // if it's the first argument, add the API key and the first argument
            if ([queryString length] == 0) {
                [queryString appendFormat:@"?api_key=%@&%@=%@", self.context.APIKey, key, [value urlEncoded]];
            } else {
                //add subsequent arguments
                [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
            }
        } else if ([self.context.APIHost isEqualToString:@"http://www.ncdc.noaa.gov"]){
            /*
             NOAA National Climatic Data Center
             */
            
            // if it's the first argument, add the API key and the first argument
            if ([queryString length] == 0) {
                [queryString appendFormat:@"?%@=%@&token=%@", key, [value urlEncoded], self.context.APIKey];
            } else {
                //add subsequent arguments
                [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
            }
        } else {
            /*
             All other APIs
             */
            if ([queryString length] == 0) {
                [queryString appendString:@"?"];
            } else {
                [queryString appendString:@"&"];
            }
            //Append the argument to the querystring we are building
            [queryString appendFormat:@"%@=%@",key, [value urlEncoded]];
        }
        //END DOL
    }
    
    //If there are arguments append them to the URL
    if ([queryString length] > 0) {
        [url appendString:queryString];
    }
    
    //The DOT FMCSA requires that the key be placed at the end.
    if ([self.context.APIHost isEqualToString:@"https://mobile.fmcsa.dot.gov"]) {
        if ([queryString length] > 0) {
            [url appendFormat:@"&webKey=%@", self.context.APIKey];
        } else {
            [url appendFormat:@"?webKey=%@", self.context.APIKey];
        }
        
    }
    
    NSLog(@"%@", url);
    
    //Create request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setDelegate:self];
    
    // DOL
    if ([self.context.APIHost isEqualToString:@"http://api.dol.gov"]) {
        //Add authorization header to the request
        [DOLDataUtils addAuthorizationHeaderToRequest:request withContext:self.context];
    } else {
        // Do nothing at this time
    }
    
        
    //Perform the request
    [request setTimeOutSeconds:timeOut];
    [request startAsynchronous];

}


#pragma mark ASIHTTP methods
//ASIHTTP invokes this method when it finishes processing a request with success
//Here is where we process the results which arrive in JSON format
//We use the JSON parser to convert to a NSDictionary and return the results to the delegate (callback)
-(void)requestFinished:(ASIHTTPRequest *)request
{
    //Log details for dubugging purposes
	NSLog(@"Webmethod returned %llu bytes", [request contentLength]);
	//NSLog(@"%@", [request responseString]);
    
    //Read response to a string.  Still called "jsonString" for convenience
    NSString *jsonString;
    
    //First, check to see if it's XML
    if ([[[request responseString] substringToIndex:1] isEqualToString:@"<"]) {
        //If XML, then parse into an NSDictionary and call the appropriate call-back method.
        NSError *error = nil;
        NSDictionary *xmlDictionaryResults = [[XMLReader dictionaryForXMLString:[request responseString] error:&error] retain];
        [self.delegate govDataRequest:self didCompleteWithDictionaryResults:xmlDictionaryResults];
        NSLog(@"The response was in XML");
    } else {
        NSLog(@"The response was in JSON");
        jsonString = [request responseString];
    }
    
    //NSLog(@"RESPONSE (%d) = \n%@", [request responseStatusCode], jsonString);
    
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
        
        [self.delegate govDataRequest:self didCompleteWithError:errorMessage];
    } else if ([[[request responseString] substringToIndex:1] isEqualToString:@"{"]){
       //Use JSON parser to convert the string into a dictionary
        
        NSDictionary *results = [jsonString JSONValue];  
        
        //Remove the JSON {d} security wrapper
        //If $filter is used, it is in an additional wrapper named results.
        NSArray *array = nil;
        
        //"Result" wrapper test and unwrap -- used for simple datasets
        if ([[results objectForKey:@"d"] isKindOfClass:[NSArray class]]) {
            array = [results objectForKey:@"d"];
        } else if ([[results objectForKey:@"d"] isKindOfClass:[NSDictionary class]]) {
            NSString *dolResultString = [NSString stringWithFormat:@"%@", [results objectForKey:@"d"]];
            NSDictionary *resultWrap = [results objectForKey:@"d"];
            array = [resultWrap objectForKey:@"results"];
            if (!array) {
                // Parse the XML for SummerJobs+
                dolResultString = [resultWrap objectForKey:@"getJobsListing"];
                NSLog(@"%@", dolResultString);
                NSError *error = nil;
                NSDictionary *xmlDictionaryResults = [[XMLReader dictionaryForXMLString:dolResultString error:&error] retain];
                NSLog(@"%@", xmlDictionaryResults);
                NSLog(@"%@", error);
                [self.delegate govDataRequest:self didCompleteWithDictionaryResults:xmlDictionaryResults];
            }
        } else {
            // return results to delegate callback with the dictionary
            NSLog(@"The response was in a dictionary");
            [self.delegate govDataRequest:self didCompleteWithDictionaryResults:results];
        }
        if (array) {
            //Return results to delegate (callback)
            [self.delegate govDataRequest:self didCompleteWithResults:array];
            NSLog(@"The response was in an array");
            
        } else if (![results isKindOfClass:[NSDictionary class]]){
            //This is the catch-all bucket for anything that couldn't be parsed.  For example, as of this writing, the census response can't be parsed as JSON.  Returns a string.
            [self.delegate govDataRequest:self didCompleteWithUnParsedResults:[request responseString]];
        }
        
        //Remove request from active request tracking list
        [activeRequests removeObject:request];
    } else if (![[[request responseString] substringToIndex:1] isEqualToString:@"<"]){
        //This is the catch-all bucket for anything that couldn't be parsed.  For example, as of this writing, the census response can't be parsed as JSON.  Returns a string.
        [self.delegate govDataRequest:self didCompleteWithUnParsedResults:[request responseString]];
        //Remove request from active request tracking list
        [activeRequests removeObject:request];
    }
}

-(void)requestFailed:(ASIHTTPRequest *)request
{
    [activeRequests removeObject:request];
	[self.delegate govDataRequest:self didCompleteWithError:[[request error]localizedDescription]];
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

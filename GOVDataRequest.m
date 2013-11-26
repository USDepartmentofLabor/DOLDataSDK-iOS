//
//  GOVDataRequest.m
//  Version 1.0
//
//  Created by the U.S. Deparment of Labor
//  Code available in the public domain
//

#import "GOVDataRequest.h"
#import "DOLDataUtils.h"
//#import "ASIHTTPRequest.h"
#import "MCCURLConnection.h"
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
    
    
    // Where appropriate, add the key.
    if ([self.context.APIHost isEqualToString:@"http://api.dol.gov"]) {
        [queryString appendFormat:@"?KEY=%@", [self.context.APIKey urlEncoded]];
    } else if ([self.context.APIHost isEqualToString:@"http://api.census.gov"] ||
               [self.context.APIHost isEqualToString:@"http://pillbox.nlm.nih.gov"]){
        [queryString appendFormat:@"?key=%@", self.context.APIKey];
    } else if ([self.context.APIHost isEqualToString:@"http://api.eia.gov"]
               || [self.context.APIHost isEqualToString:@"http://developer.nrel.gov"]
               || [self.context.APIHost isEqualToString:@"http://api.stlouisfed.org"]
               || [self.context.APIHost isEqualToString:@"http://healthfinder.gov"]){
        [queryString appendFormat:@"?api_key=%@", self.context.APIKey];
    } else if ([self.context.APIHost isEqualToString:@"http://www.ncdc.noaa.gov"]){
        [queryString appendFormat:@"?token=%@", self.context.APIKey];
    } else if ([self.context.APIHost isEqualToString:@"https://go.usa.gov"]){
        // do nothing for now
    }
    //Loop through the dictionary
    while ( (key = [enumerator nextObject]) != nil) {
        //Store value
        NSString *value = [arguments objectForKey:key];
        
        // Contstruct arguments part of query string for DOL's API
        if ([self.context.APIHost isEqualToString:@"http://api.dol.gov"]) {
      //      NSLog(@"Host is DOL!");
            //Build argument querystring. Process only valid arguments and ignore the rest
            if ([key isEqualToString:@"top"] || [key isEqualToString:@"skip"] || [key isEqualToString:@"select"]
                || [key isEqualToString:@"orderby"] || [key isEqualToString:@"filter"]) {
                //Add to querystring
                
                //Append the argument to the querystring we are building
                [queryString appendFormat:@"&$%@=%@",key, [value urlEncoded]];
            } else if ([key isEqualToString:@"format"] || [key isEqualToString:@"query"] ||[key isEqualToString:@"region"] ||[key isEqualToString:@"locality"] ||[key isEqualToString:@"skipcount"]){
                //Add to querystring
                
                [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
            }
        } else if ([self.context.APIHost isEqualToString:@"http://api.census.gov"] ||
                   [self.context.APIHost isEqualToString:@"http://pillbox.nlm.nih.gov"]){
            /*
             CENSUS.GOV API
             NIH Pillbox
             */
            
            //add subsequent arguments
            [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
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
            //add subsequent arguments
            [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
        } else if ([self.context.APIHost isEqualToString:@"http://www.ncdc.noaa.gov"]){
            /*
             NOAA National Climatic Data Center
             */
            
            // if it's the first argument, add the API key and the first argument
            //add subsequent arguments
            [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
        } else if ([self.context.APIHost isEqualToString:@"https://go.usa.gov"]){
            /*
             USA.gov URL Shortener
             */
            
            // if it's the first argument, add the API key and the first argument
            if ([queryString length] == 0) {
                [queryString appendFormat:@"?%@=%@&apiKey=%@", key, [value urlEncoded], self.context.APIKey];
            } else {
                //add subsequent arguments
                [queryString appendFormat:@"&%@=%@",key, [value urlEncoded]];
            }
        } else {
            /*
             All other APIs
             */
      //      NSLog(@"all others");
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
    /*
     
     
     
     
     look right below!
    
     
     
     
     */
    //Create request
//    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
  //  [request setDelegate:self];
 //   NSLog(@"URL is %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    
    // DOL
    if ([self.context.APIHost isEqualToString:@"http://api.dol.gov"]) {
        //Add request header to the request
//        [request addRequestHeader:@"Accept" value:@"application/json"];
        // Create a mutable copy of the immutable request and add more headers
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
        // Now set our request variable with an (immutable) copy of the altered request
        request = [mutableRequest copy];
    
        // Log the output to make sure our new headers are there
    //    NSLog(@"%@", request.allHTTPHeaderFields);
    }
    
    //Get current date/time
    NSTimeInterval then = [[NSDate date] timeIntervalSinceReferenceDate];
    //Perform the request
 
    
    [MCCURLConnection connectionWithRequest:request onFinished:^(MCCURLConnection *connection) {
        if (connection.error || (connection.httpStatusCode < 200) || (connection.httpStatusCode >= 400)) {
          //  NSLog(@"Error: %@ (status code: %ld)", connection.error, (long)connection.httpStatusCode);
            [self.delegate govDataRequest:self didCompleteWithError:[NSString stringWithFormat:@"Error: %@ (status code: %ld)", connection.error, (long)connection.httpStatusCode]];
            return;
        }
        
        NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
        
        double elapsedTime = now - then;
        
        
//        NSLog(@"Time to complete: %d", connection.response)
     //   NSURLResponse* thisResponse = connection.response;
     //   NSDictionary* headers = [(NSHTTPURLResponse *)thisResponse allHeaderFields];
     //   NSLog(@"HEADERS: %@", headers);
     //   NSLog(@"Received data length: %lu Bytes", (unsigned long)connection.data.length);

        //Read response to a string.  Still called "jsonString" for convenience
        NSString *jsonString;
        NSString *responseString = [[NSString alloc] initWithData:connection.data encoding:NSUTF8StringEncoding];
        
        //First, check to see if it's XML
        if ([[responseString substringToIndex:1] isEqualToString:@"<"]) {
            //If XML, then parse into an NSDictionary and call the appropriate call-back method.
            NSError *error = nil;
            NSDictionary *xmlDictionaryResults = [XMLReader dictionaryForXMLString:responseString error:&error];
            [self.delegate govDataRequest:self didCompleteWithDictionaryResults:xmlDictionaryResults andResponseTime:elapsedTime];
     //       NSLog(@"The response was in XML");
        } else {
     //       NSLog(@"The response was in JSON");
            jsonString = responseString;
        }
        if ([[responseString substringToIndex:1] isEqualToString:@"{"]){
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
                //    NSLog(@"%@", dolResultString);
                    NSError *error = nil;
                    NSDictionary *xmlDictionaryResults = [XMLReader dictionaryForXMLString:dolResultString error:&error];
                 //   NSLog(@"%@", xmlDictionaryResults);
                 //   NSLog(@"%@", error);
                    [self.delegate govDataRequest:self didCompleteWithDictionaryResults:xmlDictionaryResults andResponseTime:elapsedTime];
                }
            } else {
                // return results to delegate callback with the dictionary
           //     NSLog(@"The response was in a dictionary");
                [self.delegate govDataRequest:self didCompleteWithDictionaryResults:results andResponseTime:elapsedTime];
            }
            if (array) {
                //Return results to delegate (callback)
                [self.delegate govDataRequest:self didCompleteWithResults:array andResponseTime:elapsedTime];
         //       NSLog(@"The response was in an array");
                
            } else if (![results isKindOfClass:[NSDictionary class]]){
                //This is the catch-all bucket for anything that couldn't be parsed.  For example, as of this writing, the census response can't be parsed as JSON.  Returns a string.
                [self.delegate govDataRequest:self didCompleteWithUnParsedResults:responseString andResponseTime:elapsedTime];
            }
            
            //Remove request from active request tracking list
            [activeRequests removeObject:request];
        } else if (![[responseString substringToIndex:1] isEqualToString:@"<"]){
            //This is the catch-all bucket for anything that couldn't be parsed.  For example, as of this writing, the census response can't be parsed as JSON.  Returns a string.
            [self.delegate govDataRequest:self didCompleteWithUnParsedResults:responseString andResponseTime:elapsedTime];
            //Remove request from active request tracking list
            [activeRequests removeObject:request];
        }
        //[self.delegate govDataRequest:self didCompleteWithUnParsedResults:[[[NSString alloc] initWithData:connection.data encoding:NSUTF8StringEncoding] autorelease]];

    }];
    request = nil;
}


#pragma mark ASIHTTP methods
//Cancel all pending requests before destroying the object
//or else the app will crash
-(void)dealloc {
/*
    //Cancel all requests being tracked
    for (ASIHTTPRequest *request in activeRequests) { 
        request.delegate = nil;
        [request cancel];
    }
    
    //release objects
    if (activeRequests != nil)
        [activeRequests release];
*/
   // [super dealloc];
}

@end

DOLDataSDK-iOS
==============

iOS SDK to ease access to DOL's and other federal agencies' APIs.  For a list of APIs that this SDK has been tested against, please see the wiki.

Adding the SDK to Your Project
Add SDK files to your project
Copy the GOVDataSDK folder to your Xcode project.
Add Required Frameworks
Select your project and then select the project target in the middle pane. From the right pane select Build Phases. Expand the "Link Binary With Libraries" section. Add the required frameworks:
  •	libz.dylib
	•	MobileCoreServices.framework
	•	CFNetwork.framework
	•	SystemConfiguration.framework
Frameworks 
Using the SDK
Reference the DOL Data API in your source file
In the source files that will make DOL Data requests add the following imports:
#import "GOVDataRequest.h"
#import "GOVDataContext.h"
Prepare your class for delegate callbacks
The GOV Data SDK processes requests asynchronously to prevent locking up the UI while the data is requested and processed. To achieve this the SDK makes use of delegate methods. To successfully retrieve data it is required to implement the two GOVDataRequestDelegate methods and set your class as the delegate for the request. The methods will be invoked when the results have been processed or when an error occurs.
1. Implement the GOVDataRequestDelegate protocol to the class that will receive and process the API responses
Example:
@interface RootViewController : UITableViewController<GOVDataRequestDelegate>
2. Add the delegate methods to your class
//Results  delegate
-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithResults:(NSArray *)resultsArray {
     //for Standard DOL API datasets
	           //Add your code here
	           //resultsArray is an array of NSDictionaries
	           //One NSDictionary per table row 
    //for Standard DOL Data service - Summer job Plus,
	           //Add your code here
	           //resultsArray is an array of NSDictionaries
	           //Get the value of first key from NSDictionary in form of NSDictionaries.
		   //From NSDictionaries , look for "getJobsListing" which return the NSDictionary object.
		   //From getJobsListing object which is type of NSDictionaries , object using key "items" , result is an array , each element in array is job result.
			
}

-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithDictionaryResults:(NSDictionary *)resultsDictionary {
    
    // for web services that are not processed by the SDK as an array. For example, the FCC's Public Inspection Files API
    // consult the API's documentation regarding data structure or use NSLog to inspect the data
}

-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithUnParsedResults:(NSString *)resultsString {
 
    // for web services that return data that cannot be parsed by the XML or JSON parser
    // consult the API's documentation regarding data structure
}


//Error delegate  
-(void)dolDataRequest:(GOVDataRequest *)request didCompleteWithError:(NSString *)error {
	//Add your code here to show  / handle error
}
Making API Calls
The GOVDataRequest class is used to make API calls. It requires a context object to be passed to its constructor in order to get the API key and URL information needed for the requests. The GOVDataContext is the context class used to hold this information.
You can also pass arguments to the API call by adding them to a NSDictionary as key/value pairs and passing it as the second parameter of the callAPIMethod method. Valid arguments are defined later in this document
	•	Instantiate a GOVDataContext object
	•	Instantiate a GOVDataRequest object and pass the context
	•	Set your class as the delegate for the GOVDataRequest
	•	Create a NSDictionary and store all the API arguments as key/value pairs.
	•	Call the callAPIMethod method, passing the API name and the arguments (or null if there are no arguments)

Sample code to make requests for standard DOL API datasets:
//API  and URL constants
#define API_KEY @"YOUR API KEY" 
#define API_SECRET @"YOUR SHARED SECRET" 
#define  API_HOST @"http://api.dol.gov"
#define API_URL @"/V1"
/////////////////////////////////////

//Instantiate  Gov Data context object
//This  object stores the API information required to make requests
GOVDataContext *context = [[GOVDataContext alloc] initWithAPIKey:API_KEY Host:API_HOST SharedSecret:API_SECRET APIURL:API_URL]

//Instantiate  new request object. Pass the context that contains all the API key info.  This object is used even when there is no API key.
GOVDataRequest *dataRequest = [[GOVDataRequest alloc]initWithContext:context];

//Set  this class as the one that responds to the delegate methods 
dataRequest.delegate = self; 

//API  you want to fetch data from 
NSString *method = @"FORMS/Agencies"; 

//Build NSDictionary arguments
//Example to retrieve top 10 records and just get one field. 
NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:@"10", @"top", @"AgencyName", @"select", nil];

//Set the timeout.  Set this higher for long-loading APIs
int timeOut = 20;

//Make API call
[dataRequest callAPIMethod:method withArguments:arguments andTimeOut:timeOut];

The example above uses DOL's API.  Some federal APIs' URLs are structured differently.  For example, let's look at some others:

For the FCC (e.g. http://data.fcc.gov/api/block/find?latitude=40.0&longitude=-85):

	•	API_KEY = ""
	•	API_SECRET = ""
	•	API_Host = "http://data.fcc.gov"
	•	API_URL = "/api/block"
	•	method = "find"
  •	arguments = "latitude", "longitude"

For the Census Bureau (http://api.census.gov/data/2010/acs5?key={yourkey}&get=B02001_001E,NAME&for=state:06,36):
  •	API_KEY = "YOUR_API_KEY"
	•	API_SECRET = ""
	•	API_Host = "http://api.census.gov"
	•	API_URL = "/data/2010"
	•	method = "acs5"
  •	arguments = "get", "for"

//Instantiate  Gov Data context object
//This  object stores the API information required to make requests
GOVDataContext *context = [[GOVDataContext alloc] initWithAPIKey:API_KEY Host:API_HOST SharedSecret:API_SECRET APIURL:API_URL]

//Instantiate  new request object. Pass the context that contains all the API key info.  This object is used even when there is no API key.
GOVDataRequest *dataRequest = [[GOVDataRequest alloc]initWithContext:context];

//Set  this class as the one that responds to the delegate methods 
dataRequest.delegate = self; 

//API  you want to fetch data from 
NSString *method = @"SummerJobs/getJobsListing"; 

//Build NSDictionary arguments
//set value of format,query,region,locality and skipcount
//Please Note : Each String typed parameter must be surrounded in quotes in order to work correctly. 
//These quotes are then Url encoded and passed to the Service Operation.
//Each parameter that is assigned null should be left blank

NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:@"'json'", @"format", @"'farm'", @"query", @"", @"region", @"", @"locality", @"1", @"skipcount", nil];

//Set the timeout.  Set this higher for long-loading APIs
int timeOut = 20;

//Make API call
[dataRequest callAPIMethod:method withArguments:arguments andTimeOut:timeOut];

The callAPIMethod triggers the SDK to process the request, add authorization headers and invoke the delegate methods with the results or with an error message. Once the process has completed one of the three delegate methods from the GOVDataRequestDelegate   protocol will be called. If successful, the didCompleteWithResults or didCompleteWithDictionaryResults method will be called and the resultsArray or resultsDictionary parameter, depending on the format of the data you received, will contain the data you requested. If the request failed for any reason, the didCompleteWithError will be called and the error parameter will contain a description of the error.
//Results  delegate
-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithResults:(NSArray *)resultsArray {
     //for Standard DOL API datasets
	           //Add your code here
	           //resultsArray is an array of NSDictionaries
	           //One NSDictionary per table row 
    //for Standard DOL Data service - Summer job Plus,
	           //Add your code here
	           //resultsArray is an array of NSDictionaries
	           //Get the value of first key from NSDictionary in form of NSDictionaries.
		   //From NSDictionaries , look for "getJobsListing" which return the NSDictionary object.
		   //From getJobsListing object which is type of NSDictionaries , object using key "items" , result is an array , each element in array is job result.
			
}

-(void)govDataRequest:(GOVDataRequest *)request didCompleteWithDictionaryResults:(NSDictionary *)resultsDictionary {
    
    // for web services that are not processed by the SDK as an array. For example, the FCC's Public Inspection Files API
    // consult the API's documentation regarding data structure or use NSLog to inspect the data
}


//Error delegate  
-(void)dolDataRequest:(GOVDataRequest *)request didCompleteWithError:(NSString *)error {
	//Add your code here to show  / handle error
}

For API method arguments, please refer to that API's documentation

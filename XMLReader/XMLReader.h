//
//  XMLReader.h
//
//

#import <Foundation/Foundation.h>

@interface XMLReader : NSObject <NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
    NSError *__autoreleasing *errorPointer;
}

+ (NSDictionary *)dictionaryForPath:(NSString *)path error:(NSError *__autoreleasing *)errorPointer;
+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError *__autoreleasing *)errorPointer;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError *__autoreleasing *)errorPointer;

@end

@interface NSDictionary (XMLReaderNavigation)

- (id)retrieveForPath:(NSString *)navPath;

@end
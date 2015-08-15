//
//  YKParser.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Foundation/Foundation.h>
#import "yaml.h"

@interface YKParser : NSObject {
    BOOL readyToParse;
    FILE* fileInput;
    NSData *bufferInput;
    yaml_parser_t parser;
    id scanner;
}

- (void)reset;
- (BOOL)readString:(NSString *)path;
- (BOOL)readFile:(NSString *)path;
- (NSArray *)parse;
- (NSArray *)parseWithError:(NSError **)e;

@property(readonly) BOOL readyToParse;

@end

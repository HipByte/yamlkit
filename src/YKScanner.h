#import <Foundation/Foundation.h>

// YKScanner is implemented in Ruby land.
@interface YKScanner : NSObject

- (id)tokenize_from:(NSString*)string;

@end

#import <Foundation/Foundation.h>
#import "YKScanner.h"

@implementation YKScanner

// tokenize_from will be overridden in Ruby land.
- (id)tokenize_from:(NSString*)string
{
	return string;
}

@end

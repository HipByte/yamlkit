#import <Foundation/Foundation.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>

static Class hash_class = 0;
static Class symbol_class = 0;
static Class scanner_class = 0;

static Class yml_get_hash_class()
{
    if(!hash_class) {
        hash_class = NSClassFromString(@"Hash");
    }
    return hash_class;
}

static Class yml_get_symbol_class()
{
    if(!symbol_class) {
        symbol_class = NSClassFromString(@"Symbol");
    }
    return symbol_class;
}

static Class yml_get_scanner_class()
{
    if(!scanner_class) {
        scanner_class = NSClassFromString(@"YAMLKitScanner");
    }
    return scanner_class;
}

static id yml_ruby_hash_new(void)
{
    return objc_msgSend(yml_get_hash_class(), @selector(new), nil);
}

static id yml_ruby_call_scanner(NSString *string)
{
    return objc_msgSend(yml_get_scanner_class(), @selector(tokenize:), string);
}

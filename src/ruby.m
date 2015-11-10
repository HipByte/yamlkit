#import <Foundation/Foundation.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>

static Class hash_class = 0;
static Class symbol_class = 0;

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

static id yml_ruby_hash_new(void)
{
    Class hash_class = yml_get_hash_class();
    return (id)[[hash_class alloc] init];
}

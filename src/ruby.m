#import <Foundation/Foundation.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>

static Class hash_class = 0;

id yml_ruby_cstr2sym(const char* cstr)
{
    NSString *string = [NSString stringWithUTF8String:cstr];
    return objc_msgSend(string, @selector(to_sym), nil);
}

id yml_ruby_hash_new(void)
{
    if(!hash_class) {
        hash_class = NSClassFromString(@"Hash");
    }
    return objc_msgSend(hash_class, @selector(new), nil);
}


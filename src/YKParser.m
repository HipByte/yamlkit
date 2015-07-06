//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKParser.h"
#import "YKConstants.h"


static BOOL _isBooleanTrue(NSString *aString);
static BOOL _isBooleanFalse(NSString *aString);

@interface YKParser (YKParserPrivateMethods)

- (id)_interpretObjectFromEvent:(yaml_event_t)event;
- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p;

@end

@implementation YKParser

@synthesize readyToParse;

- (void)reset
{
    if(fileInput) {
        fclose(fileInput);
    }
    [bufferInput release];
    yaml_parser_delete(&parser);
    memset(&parser, 0, sizeof(parser));
}

- (BOOL)readFile:(NSString *)path
{
    [self reset];
    fileInput = fopen([path fileSystemRepresentation], "r");
    readyToParse = ((fileInput != NULL) && (yaml_parser_initialize(&parser)));
    if(readyToParse)
        yaml_parser_set_input_file(&parser, fileInput);
    return readyToParse;
}

- (BOOL)readString:(NSString *)str
{
    [self reset];
    bufferInput = [[str dataUsingEncoding:NSUTF8StringEncoding] retain];
    readyToParse = yaml_parser_initialize(&parser);
    if(readyToParse)
        yaml_parser_set_input_string(&parser, (const unsigned char *)[bufferInput bytes], [bufferInput length]);
    return readyToParse;
}

- (NSArray *)parse
{
    return [self parseWithError:NULL];
}

- (NSArray *)parseWithError:(NSError **)e
{
    yaml_event_t event;
    int done = 0;
    id obj, temp;
    NSMutableArray *stack = [NSMutableArray array];
    NSMutableDictionary *anchor = [[NSMutableDictionary alloc] init];
    NSString *anchor_name = nil; // for mapping, sequence

    if(!readyToParse) {
        if(![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]){
            if(e != NULL) {
                *e = [self _constructErrorFromParser:NULL];
                return nil;
            }
        }
    }

    while(!done) {
        if(!yaml_parser_parse(&parser, &event)) {
            if(e != NULL) {
                *e = [self _constructErrorFromParser:&parser];
            }
            return nil;
        }
        done = (event.type == YAML_STREAM_END_EVENT);
        switch(event.type) {
          case YAML_SCALAR_EVENT:
            obj = [self _interpretObjectFromEvent:event];

            [self _setObject:obj In:stack WithError:e];
            if (e != nil) {
                return nil;
            }
            if (event.data.scalar.anchor) {
                [anchor setObject:obj forKey:[NSString stringWithUTF8String:event.data.scalar.anchor]];
            }
            break;

          case YAML_SEQUENCE_START_EVENT:
            [stack addObject:[NSMutableArray array]];
            if (event.data.sequence_start.anchor) {
                anchor_name = [NSString stringWithUTF8String:event.data.sequence_start.anchor];
            }
            break;

          case YAML_MAPPING_START_EVENT:
            [stack addObject:[NSMutableDictionary dictionary]];
            if (event.data.mapping_start.anchor) {
                anchor_name = [NSString stringWithUTF8String:event.data.mapping_start.anchor];
            }
            break;

          case YAML_SEQUENCE_END_EVENT:
          case YAML_MAPPING_END_EVENT:
            // TODO: Check for retain count errors.
            obj = [stack lastObject];
            [stack removeLastObject];

            [self _setObject:obj In:stack WithError:e];
            if (e != nil) {
                return nil;
            }

            if (anchor_name) {
                [anchor setObject:obj forKey:anchor_name];
                anchor_name = nil;
            }
            break;

          case YAML_ALIAS_EVENT:
            if (event.data.alias.anchor) {
                obj = [anchor objectForKey:[NSString stringWithUTF8String:event.data.alias.anchor]];
                [self _setObject:obj In:stack WithError:e];
                if (e != nil) {
                    return nil;
                }
            }
            break;

          case YAML_NO_EVENT:
            break;

          default:
            break;
        }
        yaml_event_delete(&event);
    }
    return stack;
}

- (void)_setObject:(id)obj In:(NSMutableArray *)stack WithError:(NSError **)e
{
    id temp = [stack lastObject];

    if(temp == nil) {
        [stack addObject:obj];
    } else if([temp isKindOfClass:[NSArray class]]) {
        [temp addObject:obj];
    } else if([temp isKindOfClass:[NSDictionary class]]) {
        [stack addObject:obj];
    } else if([temp isKindOfClass:[NSString class]] || [temp isKindOfClass:[NSValue class]])  {
        [temp retain];
        [stack removeLastObject];
        if(![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]){
            if(e != NULL) {
                *e = [self _constructErrorFromParser:NULL];
                return;
            }
        }
        [[stack lastObject] setObject:obj forKey:temp];
    }
}

// TODO: oof, add tag support.

- (id)_interpretObjectFromEvent:(yaml_event_t)event
{
    NSString *stringValue = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
    id obj = stringValue;

    if(event.data.scalar.style == YAML_PLAIN_SCALAR_STYLE) {
        NSScanner *scanner = [NSScanner scannerWithString:obj];

        // Integers are automatically casted unless given a !!str tag. I think.
        id val = [self _convertToNumberFromString:stringValue];
        if(val) {
            return val;
        }

        if(_isBooleanTrue((NSString *)obj)) {
            obj = [NSNumber numberWithBool:YES];
        } else if(_isBooleanFalse((NSString *)obj)) {
            obj = [NSNumber numberWithBool:NO];
        } else if([obj isEqualToString:@"~"]) {
            obj = [NSNull null];
        }
        // TODO: add date parsing.
    }
    return obj;
}

- (NSNumber*)_convertToNumberFromString:(NSNumber*)string
{
    char *str = [string UTF8String];
    long len = strlen(str);
    bool is_hex = false;
    bool is_float = false;

    for(int i = 0; i < len; i++) {
        char c = str[i];
        if(!isdigit(c)) {
            if(str[0] == '0' && c == 'x' && !is_hex) {
                is_hex = true;
            } else if(c == '.' && !is_float) {
                is_float = true;
            } else if(is_hex && (('a' <= c && c <= 'f') || ('A' <= c && c <= 'F'))) {
                continue;
            } else {
                return nil;
            }
        }
    }

    NSNumber *result = nil;
    long value;
    if(str[0] == '0' && !is_hex && !is_float) {
        value = strtoll(str, NULL, 8);
        result = [NSNumber numberWithLong:value];
    } else if(is_hex) {
        value = strtoll(str, NULL, 16);
        result = [NSNumber numberWithLong:value];
    } else if(is_float) {
        result = [NSNumber numberWithDouble:[string doubleValue]];
    } else {
        result = [NSNumber numberWithLongLong:[string longLongValue]];
    }

    return result;
}

- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p
{
    int code = 0;
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    if(p != NULL) {
        // actual parser error
        code = p->error;
        // get the string encoding.
        NSStringEncoding enc = 0;
        switch (p->encoding) {
          case YAML_UTF8_ENCODING:
            enc = NSUTF8StringEncoding;
            break;
          case YAML_UTF16LE_ENCODING:
            enc = NSUTF16LittleEndianStringEncoding;
            break;
          case YAML_UTF16BE_ENCODING:
            enc = NSUTF16BigEndianStringEncoding;
            break;
          default: break;
        }
        [data setObject:[NSNumber numberWithInt:enc] forKey:NSStringEncodingErrorKey];

        [data setObject:[NSString stringWithUTF8String:p->problem] forKey:YKProblemDescriptionKey];
        [data setObject:[NSNumber numberWithInt:p->problem_offset] forKey:YKProblemOffsetKey];
        [data setObject:[NSNumber numberWithInt:p->problem_value] forKey:YKProblemValueKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.line] forKey:YKProblemLineKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.index] forKey:YKProblemIndexKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.column] forKey:YKProblemColumnKey];

        [data setObject:[NSString stringWithUTF8String:p->context] forKey:YKErrorContextDescriptionKey];
        [data setObject:[NSNumber numberWithInt:p->context_mark.line] forKey:YKErrorContextLineKey];
        [data setObject:[NSNumber numberWithInt:p->context_mark.column] forKey:YKErrorContextColumnKey];
        [data setObject:[NSNumber numberWithInt:p->context_mark.index] forKey:YKErrorContextIndexKey];

    } else if(readyToParse) {
        [data setObject:NSLocalizedString(@"Internal assertion failed, possibly due to specially malformed input.", @"") forKey:NSLocalizedDescriptionKey];
    } else {
        [data setObject:NSLocalizedString(@"YAML parser was not ready to parse.", @"") forKey:NSLocalizedFailureReasonErrorKey];
        [data setObject:NSLocalizedString(@"Did you remember to call readFile: or readString:?", @"") forKey:NSLocalizedDescriptionKey];
    }

    return [[NSError alloc] initWithDomain:YKErrorDomain code:code userInfo:data];
}

- (void)finalize
{
    yaml_parser_delete(&parser);
    if(fileInput != NULL) fclose(fileInput);
    [bufferInput release];
    [super finalize];
}

- (void)dealloc
{
    yaml_parser_delete(&parser);
    if(fileInput != NULL) fclose(fileInput);
    [bufferInput release];
    [super dealloc];
}

@end

static BOOL _isBooleanFalse(NSString *aString)
{
    BOOL isFalse = NO;
    const char *cstr = [aString UTF8String];
    char *falseValues[] = {
        "false", "False", "FALSE",
        "n", "N", "NO", "No", "no",
        "off", "Off", "OFF"
    };
    size_t length = sizeof(falseValues) / sizeof(*falseValues);
    int index;
    for(index = 0; index < length && !isFalse; index++) {
        isFalse = strcmp(cstr, falseValues[index]) == 0;
    }
    return isFalse;
}

static BOOL _isBooleanTrue(NSString *aString)
{
    BOOL isTrue = NO;
    const char *cstr = [aString UTF8String];
    char *trueValues[] = {
        "true", "TRUE", "True",
        "y", "Y", "Yes", "yes", "YES",
        "on", "On", "ON"
    };
    size_t length = sizeof(trueValues) / sizeof(*trueValues);
    int index;
    for(index = 0; index < length && !isTrue; index++) {
        isTrue = strcmp(cstr, trueValues[index]) == 0;
    }
    return isTrue;
}

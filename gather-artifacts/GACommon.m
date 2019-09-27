/**
 @file          GACommon.m
 @package       gather-artifacts
 @brief         Common functions.

 @author        Edward Smith
 @date          September 23, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import "GACommon.h"

NSError* NSErrorWithCodeFileLine(NSInteger code, NSString*filename, NSInteger linenumber) {
    filename = [filename lastPathComponent];
    return [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{
        @"Filename": (filename) ? filename : @"None",
        @"Linenumber": @(linenumber)
    }];
}

NSError*GAWritef(NSFileHandle*file, NSString*format, ...) {
    va_list args;
    va_start(args, format);
    NSMutableString* message = [[NSMutableString alloc] initWithFormat:format arguments:args];
    [message appendString:@"\n"];
    va_end(args);
    @try {
        [file writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
        return NSErrorWithCode(NSFileWriteUnknownError);
    }
    return nil;
}

NSString* GAProjectFilename(NSString*filename) {
    // TODO: Fix this part.
    NSString*kPrefix = @"/Users/edwardsmith/Development/ios/";
    if ([filename hasPrefix:kPrefix]) {
        return [filename substringFromIndex:kPrefix.length];
    }
    return filename;
}

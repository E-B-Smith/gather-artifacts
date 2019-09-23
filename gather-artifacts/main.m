/**
 @file          main.m
 @package       gather-artifacts
 @brief         Command line utility to gather Xcode test artifacts.

 @author        Edward Smith
 @date          September 22, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import <Foundation/Foundation.h>
#import <sysexits.h>
#import "GACommandOptions.h"
#import "BNCLog.h"

static BNCLogLevel global_logLevel = BNCLogLevelWarning;

void LogOutputFunction(
        NSDate*_Nonnull timestamp,
        BNCLogLevel level,
        NSString *_Nullable message
    ) {
    if (level < global_logLevel || !message) return;
    NSRange range = [message rangeOfString:@") "];
    if (range.location != NSNotFound) {
        message = [message substringFromIndex:range.location+2];
    }
    NSData *data = [message dataUsingEncoding:NSNEXTSTEPStringEncoding];
    if (!data) return;
    int descriptor = (level == BNCLogLevelLog) ? STDOUT_FILENO : STDERR_FILENO;
    write(descriptor, data.bytes, data.length);
    write(descriptor, "\n   ", sizeof('\n'));
}

int main(int argc, char*const argv[]) {
    int returnCode = EXIT_FAILURE;
    @autoreleasepool {
        BNCLogSetOutputFunction(LogOutputFunction);
        BNCLogSetDisplayLevel(BNCLogLevelWarning);

        __auto_type options = [GACommandOptions commandLineOptionsWithArgc:argc argv:argv];
        if (options.badOptionsError) {
            returnCode = EX_USAGE;
            goto exit;
        }
        if (options.showHelp) {
            NSData *data = [[GACommandOptions helpString] dataUsingEncoding:NSUTF8StringEncoding];
            write(STDOUT_FILENO, data.bytes, data.length);
            returnCode = EXIT_SUCCESS;
            goto exit;
        }
        if (options.showVersion) {
            __auto_type version = [NSString stringWithFormat:@"%@(%@)\n",
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
            ];
            NSData *data = [version dataUsingEncoding:NSUTF8StringEncoding];
            write(STDOUT_FILENO, data.bytes, data.length);
            returnCode = EXIT_SUCCESS;
            goto exit;
        }
        global_logLevel =
            MIN(MAX(BNCLogLevelWarning - options.verbosity, BNCLogLevelAll), BNCLogLevelNone);
        BNCLogSetDisplayLevel(global_logLevel);
        
    }
exit:
    return returnCode;
}

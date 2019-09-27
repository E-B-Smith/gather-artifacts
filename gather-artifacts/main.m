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
#import "GAOptions.h"
#import "GAJUnit.h"
#import "GACoverage.h"
#import "GACommon.h"
#import "BNCLog.h"
#include <glob.h>

NSArray<NSString*>*_Nonnull GAGlobPathname(NSString*pattern) {
    glob_t glob_data;
    NSMutableArray<NSString*>*globs = NSMutableArray.new;
    {
        glob_data.gl_matchc = 1000;
        int err = glob([pattern cStringUsingEncoding:NSNEXTSTEPStringEncoding],
            GLOB_TILDE | GLOB_BRACE | GLOB_LIMIT, NULL, &glob_data);
        if (err != 0) goto exit;
        for (int i = 0; i < glob_data.gl_matchc; ++i) {
            [globs addObject:
                [NSString stringWithCString:glob_data.gl_pathv[i] encoding:NSNEXTSTEPStringEncoding]];
        }
    }
exit:
    globfree(&glob_data);
    return globs;
}

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

        __auto_type options = [GAOptions optionsWithArgc:argc argv:argv];
        if (options.badOptionsError) {
            returnCode = EX_USAGE;
            goto exit;
        }
        if (options.showHelp) {
            NSData *data = [[GAOptions helpString] dataUsingEncoding:NSUTF8StringEncoding];
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

        NSFileHandle*stdError = [NSFileHandle fileHandleWithStandardError];

        // Find the test plist file:
        NSString*glob = [NSString stringWithFormat:@"%@/**/*TestSummaries.plist", options.inputDirectory];
        NSArray<NSString*>*plists = GAGlobPathname(glob);
        if (plists.count == 0) {
            GAWritef(stdError, @"Can't find test summary with glob '%@'.", glob);
            goto exit;
        }
        glob = [NSString stringWithFormat:@"%@/**/*.xccovarchive", options.inputDirectory];
        NSArray<NSString*>*xccovarchives = GAGlobPathname(glob);
        if (xccovarchives.count == 0) {
            GAWritef(stdError, @"Can't find xccovarchive with glob '%@'.", glob);
            goto exit;
        }

        NSString*junitOut = [NSString stringWithFormat:@"%@/report.junit", options.outputDirectory];
        NSError*error = GAJUnitWithInput(plists[plists.count-1], junitOut);
        if (error) {
            GAWritef(stdError, @"%@", error.localizedDescription);
            goto exit;
        }

        NSString*coverageOut = [NSString stringWithFormat:@"%@/coverage.coverage", options.outputDirectory];
        error = GACoverageWithInput(xccovarchives[xccovarchives.count-1], coverageOut);
        if (error) {
            GAWritef(stdError, @"%@", error.localizedDescription);
            goto exit;
        }

    returnCode = EXIT_SUCCESS;
    }
exit:
    return returnCode;
}

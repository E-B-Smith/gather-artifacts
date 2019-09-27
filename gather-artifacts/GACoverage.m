/**
 @file          GACoverage.m
 @package       gather-artifacts
 @brief         Create a coverage report.

 @author        Edward Smith
 @date          September 23, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import "GACoverage.h"
#import "GACommon.h"
#import "BNCLog.h"

NSError*_Nullable GAErrorFromTaskTermination(NSTask*task) {
    if (task.terminationStatus != 0) {
        return [NSError errorWithDomain:NSPOSIXErrorDomain code:task.terminationStatus userInfo:nil];
    }
    if (task.terminationReason != NSTaskTerminationReasonExit) {
        return [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:nil];
    }
    return nil;
}

NSError*_Nullable GACoverageWithInput(NSString*xccovarchive, NSString*output) {
    BNCLogDebug(@"Create coverage from '%@'.", xccovarchive);
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:output contents:nil attributes:nil];
    if (!success) return NSErrorWithCode(NSURLErrorCannotWriteToFile);
    __auto_type fout = [NSFileHandle fileHandleForWritingAtPath:output];

    NSPipe*fileListPipe = [[NSPipe alloc] init];
    NSTask*fileListTask = [[NSTask alloc] init];
    fileListTask.launchPath = @"/usr/bin/xcrun";
    fileListTask.arguments = @[ @"xccov", @"view", @"--file-list", xccovarchive ];
    fileListTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
    fileListTask.standardOutput = fileListPipe;
    [fileListTask launch];
    NSMutableData*data = [NSMutableData data];
    do  {
        __auto_type chunk = [[fileListPipe fileHandleForReading] readDataToEndOfFile];
        [data appendData:chunk];
    } while (fileListTask.isRunning);
    __auto_type error = GAErrorFromTaskTermination(fileListTask);
    if (error) return error;
    __auto_type string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    __auto_type files = [string componentsSeparatedByString:@"\n"];
    for (NSString*file in files) {
        NSString*trimFile = [file stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimFile.length == 0) continue;

        BNCLogDebug(@"Creating coverage for '%@'.", file);
        NSPipe*coveragePipe = [[NSPipe alloc] init];
        NSTask*coverageTask = [[NSTask alloc] init];
        coverageTask.launchPath = @"/usr/bin/xcrun";
        coverageTask.arguments = @[ @"xccov", @"view", @"--file", trimFile, xccovarchive ];
        coverageTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
        coverageTask.standardOutput = coveragePipe;
        [coverageTask launch];
        NSMutableData*data = [NSMutableData data];
        do  {
            __auto_type chunk = [[coveragePipe fileHandleForReading] readDataToEndOfFile];
            [data appendData:chunk];
        } while (coverageTask.isRunning);
        __auto_type error = GAErrorFromTaskTermination(coverageTask);
        if (error) return error;
        __auto_type coverage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        error = GAWritef(fout, @"File: %@", trimFile);
        if (error) return error;
        error = GAWritef(fout, @"%@", coverage);
        if (error) return error;
    }
    [fout closeFile];
    return nil;
}

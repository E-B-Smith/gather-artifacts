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
    __auto_type fout = [NSFileHandle fileHandleForWritingAtPath:output];

    NSPipe*fileListPipe = [[NSPipe alloc] init];
    NSTask*fileListTask = [[NSTask alloc] init];
    fileListTask.launchPath = @"/usr/bin/xcrun";
    fileListTask.arguments = @[ @"xccov", @"view", @"--file-list", xccovarchive ];
    fileListTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
    fileListTask.standardOutput = fileListPipe;
    [fileListTask launch];
    __auto_type data = [[fileListPipe fileHandleForReading] readDataToEndOfFile];
    __auto_type error = GAErrorFromTaskTermination(fileListTask);
    if (error) return error;
    __auto_type string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    __auto_type files = [string componentsSeparatedByString:@"\n"];
    for (NSString*file in files) {
        NSString*trimFile = [file stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimFile.length == 0) continue;

        NSPipe*coveragePipe = [[NSPipe alloc] init];
        NSTask*coverageTask = [[NSTask alloc] init];
        coverageTask.launchPath = @"/usr/bin/xcrun";
        coverageTask.arguments = @[ @"xccov", @"view", @"--file", trimFile, xccovarchive ];
        coverageTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
        coverageTask.standardOutput = coveragePipe;
        [coverageTask launch];
        __auto_type data = [[coveragePipe fileHandleForReading] readDataToEndOfFile];
        __auto_type error = GAErrorFromTaskTermination(coverageTask);
        if (error) return error;
        __auto_type coverage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        error = GAWritef(fout, @"File: %@", trimFile);
        if (error) return error;
        error = GAWritef(fout, @"%@", coverage);
        if (error) return error;
    }
    return nil;
}

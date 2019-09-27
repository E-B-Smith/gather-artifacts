/**
 @file          GAJUnit.m
 @package       gather-artifacts
 @brief         Create JUnit xml from Xcode build result plist.

 @author        Edward Smith
 @date          September 22, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import "GAJUnit.h"
#import <sysexits.h>
#import "BNCLog.h"
#import "GACommon.h"

typedef NS_ENUM(NSInteger, GATestStatus) {
    GATestStatusUnknown = 0,
    GATestStatusPass,
    GATestStatusFail,
    GATestStatusSkipped,
};

GATestStatus GATestStatusFromString(NSString* string) {
    if (![string isKindOfClass:NSString.class])
        return GATestStatusUnknown;
    if ([string isEqualToString:@"Success"])
        return GATestStatusPass;
    if ([string isEqualToString:@"Failure"])
        return GATestStatusFail;
    if ([string isEqualToString:@"Skipped"])
        return GATestStatusSkipped;
    return GATestStatusUnknown;
}

#pragma mark -

@interface GATestFailure : NSObject
@property (nonatomic, retain) NSString* filename;
@property (nonatomic, assign) NSInteger linenumber;
@property (nonatomic, retain) NSString* message;
+ (GATestFailure*) failureFromDictionary:(NSDictionary*)dictionary;
@end

@implementation GATestFailure

+ (GATestFailure*) failureFromDictionary:(NSDictionary*)dictionary {
    GATestFailure* failure = [GATestFailure new];
    failure.filename = dictionary[@"FileName"];
    failure.linenumber = [dictionary[@"LineNumber"] integerValue];
    failure.message = dictionary[@"Message"];
    return (failure.filename == nil && failure.message == nil) ? nil : failure;
}

@end

#pragma mark -

@interface GATestCase : NSObject
@property (nonatomic, strong) GATestCase                      *parent;
@property (nonatomic, strong) NSString                        *name;
@property (nonatomic, assign) NSTimeInterval                   duration;
@property (nonatomic, assign) GATestStatus                     status;
@property (nonatomic, strong) NSMutableArray<GATestFailure*>  *failures;
@property (nonatomic, assign) NSInteger                        testCount;
@property (nonatomic, assign) NSInteger                        failureCount;
+ (GATestCase*) testWithParent:(GATestCase*)parent dictionary:(NSDictionary*)dictionary;
@end

NSMutableArray<GATestCase*>*allTests;

@implementation GATestCase

+ (GATestCase*) testWithParent:(GATestCase*)parent dictionary:(NSDictionary*)dictionary {
    GATestCase*testCase = [GATestCase new];
    testCase.parent = parent;
    testCase.name = dictionary[@"TestName"];
    testCase.status = GATestStatusFromString(dictionary[@"TestStatus"]);
    testCase.duration = [dictionary[@"Duration"] doubleValue];
    testCase.failures = [NSMutableArray new];
    for (NSDictionary*failure in dictionary[@"FailureSummaries"]) {
        GATestFailure*fail = [GATestFailure failureFromDictionary:failure];
        if (fail) [testCase.failures addObject:fail];
    }
    NSDictionary*subtests = dictionary[@"Subtests"];
    if (!subtests) subtests = dictionary[@"Tests"];

    if (subtests) {
        for (NSDictionary*subdict in subtests) {
            [GATestCase testWithParent:testCase dictionary:subdict];
        }
    } else {
        if (!allTests) allTests = NSMutableArray.new;
        [allTests addObject:testCase];
    }
    [testCase addToParentTestCount:1];
    [testCase addToParentFailureCount:testCase.failures.count];
    return testCase;
}

- (void) addToParentTestCount:(NSInteger)testCount {
    GATestCase*parent = self.parent;
    while (parent) {
        parent.testCount += testCount;
        parent = parent.parent;
    }
}

- (void) addToParentFailureCount:(NSInteger)failCount {
    GATestCase*parent = self.parent;
    while (parent) {
        parent.failureCount += failCount;
        parent = parent.parent;
    }
}

- (NSString*) description {
    NSMutableString*string = [NSMutableString new];
    [string appendString:self.name];
    GATestCase*parent = self.parent;
    while (parent) {
        [string appendFormat:@".%@", parent.name];
        parent = parent.parent;
    }
    return [NSString stringWithFormat:@"Failures: %ld %@", self.failures.count, string];
}

- (GATestCase*) testSuite { return self.parent; }
- (GATestCase*) testSuites { return self.parent.parent; }

@end

#pragma mark -

NSError*_Nullable GAJUnitWithInput(
    NSString*_Nonnull input,
    NSString*_Nonnull output
) {
    NSError*error = nil;
    __auto_type data = [NSData dataWithContentsOfFile:input options:0 error:&error];
    if (error) return error;
    NSDictionary*plist =
        [NSPropertyListSerialization propertyListWithData:data
            options:NSPropertyListImmutable
            format:nil
            error:&error];
    if (error) return error;
    if (![plist isKindOfClass:[NSDictionary class]])
        return NSErrorWithCode(NSPropertyListReadCorruptError);
    NSString*version = plist[@"FormatVersion"];
    if (![version isKindOfClass:[NSString class]])
        return NSErrorWithCode(NSPropertyListReadCorruptError);
    double doubleVersion = [version doubleValue];
    if (doubleVersion < 1.0 || doubleVersion >= 2.0)
        return NSErrorWithCode(NSPropertyListReadUnknownVersionError);

    for (NSDictionary*suiteDictionary in plist[@"TestableSummaries"]) {
        [GATestCase testWithParent:nil dictionary:suiteDictionary];
    }

    __auto_type fout = [NSFileHandle fileHandleForWritingAtPath:output];
    error = GAWritef(fout, @"<?xml version='1.0' encoding='UTF-8'?>");
    if (error) return error;
    
    GATestCase*lastTestSuites = nil;
    GATestCase*lastTestSuite = nil;
    for (GATestCase*test in allTests) {
        if (lastTestSuites != test.testSuites && lastTestSuites) {
            if (lastTestSuite)
                GAWritef(fout, @"  </testsuite>");
            GAWritef(fout, @"</testsuites>");
            lastTestSuites = nil;
            lastTestSuite = nil;
        }
        if (lastTestSuites != test.testSuites) {
            GAWritef(fout, @"<testsuites name='%@' tests='%ld' failures='%ld'>",
                test.testSuites.name,
                test.testSuites.testCount,
                test.testSuites.failureCount
            );
            lastTestSuites = test.testSuites;
        }
        if (lastTestSuite != test.testSuite) {
            if (lastTestSuite != nil)
                GAWritef(fout, @"  </testsuite>");
            GAWritef(fout, @"  <testsuite name='%@' tests='%ld' failures='%ld'>",
                test.testSuite.name,
                test.testSuite.testCount,
                test.testSuite.failureCount
            );
            lastTestSuite = test.testSuite;
        }
        if (test.failures.count == 0) {
            GAWritef(fout, @"    <testcase classname='%@' name='%@' time='%1.3f'/>",
                test.testSuite.name,
                test.name,
                test.duration
            );
        } else {
            GAWritef(fout, @"    <testcase classname='%@' name='%@' time='%1.3f'>",
                test.testSuite.name,
                test.name,
                test.duration
            );
            for (GATestFailure*fail in test.failures) {
                GAWritef(fout, @"      <failure message='%@:%ld'>\n%@",
                    GAProjectFilename(fail.filename),
                    fail.linenumber,
                    fail.message
                );
                GAWritef(fout, @"      </failure>");
            }
            GAWritef(fout, @"    </testcase>");
        }
    }
    if (lastTestSuite)
        GAWritef(fout, @"  </testsuite>");
    if (lastTestSuites)
        GAWritef(fout, @"</testsuites>");
    return nil;
}

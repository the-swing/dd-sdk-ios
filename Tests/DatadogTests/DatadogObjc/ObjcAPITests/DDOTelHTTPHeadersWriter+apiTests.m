/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-2020 Datadog, Inc.
*/

#import <XCTest/XCTest.h>
@import DatadogObjc;

@interface DDOTelHTTPHeadersWriter_apiTests : XCTestCase
@end

/*
 * `DatadogObjc` APIs smoke tests - only check if the interface is available to Objc.
 */
@implementation DDOTelHTTPHeadersWriter_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)testInitWithSamplingRate {
    [[DDOTelHTTPHeadersWriter alloc] initWithSamplingRate:100 injectEncoding:DDInjectEncodingSingle];
}

#pragma clang diagnostic pop

@end

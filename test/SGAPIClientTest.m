//
//  SGAPIClientTest.m
//  SimpleGeo.framework
//
//  Copyright (c) 2010, SimpleGeo Inc.
//  All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the <organization> nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <GHUnit/GHUnit.h>
#import "SGAPIClient.h"
#import "SGAPIClient+Places.h"


NSString * const TEST_URL_PREFIX = @"http://localhost:4567/";


@interface SGAPIClientTest : GHAsyncTestCase <SGAPIClientDelegate> { }
@end


@implementation SGAPIClientTest

- (BOOL)shouldRunOnMainThread
{
    return NO;
}

#pragma mark Utility Methods

- (SGAPIClient *)createClient
{
    NSURL *url = [NSURL URLWithString:TEST_URL_PREFIX];
    return [[[SGAPIClient clientWithDelegate:self
                                 consumerKey:@"consumerKey"
                              consumerSecret:@"consumerSecret"
                                         URL:url] retain] autorelease];
}

- (SGPoint *)point
{
    return [[[SGPoint pointWithLatitude:40.0 longitude:-105.0] retain] autorelease];
}

#pragma mark Tests

- (void)testCreateWithDefaultURL
{
    NSURL *url = [NSURL URLWithString:SIMPLEGEO_URL_PREFIX];
    GHTestLog(@"SimpleGeo URL prefix: %@", SIMPLEGEO_URL_PREFIX);
    SGAPIClient *client = [SGAPIClient clientWithDelegate:self
                                              consumerKey:@""
                                           consumerSecret:@""];

    GHAssertEqualObjects([client url], url, @"URLs don't match.");
}

- (void)testCreateWithURL
{
    NSURL *url = [NSURL URLWithString:TEST_URL_PREFIX];
    SGAPIClient *client = [SGAPIClient clientWithDelegate:self
                                              consumerKey:@""
                                           consumerSecret:@""
                                                      URL:url];

    GHAssertEqualObjects([client url], url, @"URLs don't match.");
}

#pragma mark Async Tests

- (void)testGetFeatureWithId
{
    [self prepare];

    SGAPIClient *client = [self createClient];

    [client getFeatureWithId:@"SG_4CsrE4oNy1gl8hCLdwu0F0"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testGetFeatureWithIdAndNonExistentResult
{
    [self prepare];

    SGAPIClient *client = [self createClient];

    [client getFeatureWithId:@"foo"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testGetFeatureWithIdAndBadCredentials
{
    [self prepare];

    NSURL *url = [NSURL URLWithString:TEST_URL_PREFIX];
    SGAPIClient *client = [SGAPIClient clientWithDelegate:self
                                              consumerKey:@"invalidKey"
                                           consumerSecret:@"invalidSecret"
                                                      URL:url];

    [client getFeatureWithId:@"badCredentials"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testGetFeatureWithIdShouldCallRequestDidFinish
{
    [self prepare];

    SGAPIClient *client = [self createClient];

    [client getFeatureWithId:@"requestDidFinish"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testGetPlacesNearWithMultipleResults
{
    [self prepare];

    [[self createClient] getPlacesNear:[self point]];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testGetPlacesNearMatchingWithASingleResult
{
    [self prepare];

    [[self createClient] getPlacesNear:[self point]
                              matching:@"one"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testGetPlacesNearMatchingInCategory
{
    [self prepare];

    [[self createClient] getPlacesNear:[self point]
                              matching:@"burgers"
                            inCategory:@"Restaurants"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testUpdatePlace
{
    [self prepare];

    NSString *handle = @"SG_4CsrE4oNy1gl8hCLdwu0F0_47.046962_-122.937467@1290636830";

    SGFeature *feature = [SGFeature featureWithId:handle
                                       properties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"Mike's Burger Shack", @"name",
                                                   nil]];

    [[self createClient] updatePlace:handle
                                with:feature];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

- (void)testDeletePlace
{
    [self prepare];

    [[self createClient] deletePlace:@"SG_4CsrE4oNy1gl8hCLdwu0F0_47.046962_-122.937467@1290636830"];

    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:0.25];
}

#pragma mark SGAPIClientDelegate Methods

- (void)requestDidFinish:(ASIHTTPRequest *)request
{
    NSLog(@"requestDidFinish: %@", [request userInfo]);
    if ([[[request userInfo] objectForKey:@"featureId"] isEqual:@"requestDidFinish"]) {
        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetFeatureWithIdShouldCallRequestDidFinish)];
    }
}

- (void)requestDidFail:(ASIHTTPRequest *)request
{
    NSLog(@"requestDidFail: %@", [request userInfo]);
    if ([[[request userInfo] objectForKey:@"featureId"] isEqual:@"badCredentials"]) {
        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetFeatureWithIdAndBadCredentials)];
    }
}

- (void)didDeletePlace:(NSString *)handle
                 token:(NSString *)token
{
    GHAssertEqualObjects(handle, @"SG_4CsrE4oNy1gl8hCLdwu0F0_47.046962_-122.937467@1290636830", nil);
    GHAssertEqualObjects(token, @"8fa0d1c4fc2911dfa39058b035fcf1e5", nil);

    [self notify:kGHUnitWaitStatusSuccess
     forSelector:@selector(testDeletePlace)];
}

- (void)didLoadFeature:(SGFeature *)feature
                withId:(NSString *)featureId
{
    if ([featureId isEqual:@"SG_4CsrE4oNy1gl8hCLdwu0F0"]) {
        GHAssertEqualObjects([feature featureId], @"SG_4CsrE4oNy1gl8hCLdwu0F0_47.046962_-122.937467@1290636830", nil);

        GHAssertEquals([[feature geometry] latitude], 47.046962, nil);
        GHAssertEquals([[feature geometry] longitude], -122.937467, nil);

        GHAssertEqualObjects([[feature properties] objectForKey:@"name"], @"Burger Master West Olympia", nil);

        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetFeatureWithId)];
    } else if ([featureId isEqual:@"foo"]) {
        GHAssertNil(feature, nil);

        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetFeatureWithIdAndNonExistentResult)];
    }
}

- (void)didLoadPlaces:(SGFeatureCollection *)places
                 near:(SGPoint *)point
             matching:(NSString *)query
           inCategory:(NSString *)category
{
    if (!query && !category) {
        GHAssertEqualObjects(point, [self point], @"Reference point didn't match");
        GHAssertEquals([places count], (NSUInteger) 7, @"Should have been 7 places.");
        GHAssertEqualObjects([[[[places features] objectAtIndex:0] properties] objectForKey:@"name"],
                             @"Burger Master West Olympia", nil);
        GHAssertEqualObjects([[[[places features] objectAtIndex:1] properties] objectForKey:@"name"],
                             @"Red Robin Gourmet Burgers", nil);

        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetPlacesNearWithMultipleResults)];
    } else if ([query isEqual:@"one"]) {
        GHAssertEqualObjects(point, [self point], @"Reference point didn't match");
        GHAssertEqualObjects(query, @"one", nil);
        GHAssertEquals([places count], (NSUInteger) 1, @"Should have been 1 place.");
        NSArray *features = [places features];
        GHAssertEqualObjects([[[features objectAtIndex:0] properties] objectForKey:@"name"],
                             @"Burger Master West Olympia", nil);

        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetPlacesNearMatchingWithASingleResult)];
    } else if ([query isEqual:@"burgers"]) {
        GHAssertEqualObjects(point, [self point], @"Reference point didn't match");
        GHAssertEqualObjects(query, @"burgers", nil);
        GHAssertEqualObjects(category, @"Restaurants", nil);
        GHAssertEquals([places count], (NSUInteger) 7, @"Should have been 7 places.");
        NSArray *features = [places features];
        GHAssertEqualObjects([[[features objectAtIndex:0] properties] objectForKey:@"name"],
                             @"Burger Master West Olympia", nil);
        GHAssertEqualObjects([[[[places features] objectAtIndex:1] properties] objectForKey:@"name"],
                             @"Red Robin Gourmet Burgers", nil);

        [self notify:kGHUnitWaitStatusSuccess
         forSelector:@selector(testGetPlacesNearMatchingInCategory)];
    }
}

- (void)didUpdatePlace:(NSString *)handle
                 token:(NSString *)token
{
    GHAssertEqualObjects(handle, @"SG_4CsrE4oNy1gl8hCLdwu0F0_47.046962_-122.937467@1290636830", nil);
    GHAssertEqualObjects(token, @"79ea18ccfc2911dfa39058b035fcf1e5", nil);

    [self notify:kGHUnitWaitStatusSuccess
     forSelector:@selector(testUpdatePlace)];
}

@end

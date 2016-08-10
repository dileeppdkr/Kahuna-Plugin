/*
 * Kahuna CONFIDENTIAL
 * __________________
 *
 *  2014 Kahuna, Inc.
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Kahuna, Inc. and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to Kahuna, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Kahuna, Inc.
 */
//
//  KahunaPlugin.h
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import "Kahuna.h"

@interface KahunaPlugin : CDVPlugin <KahunaDelegate> {
    NSString *_callbackId;
}

- (void)startWithKey:(CDVInvokedUrlCommand*)command;
- (void)launchWithKey:(CDVInvokedUrlCommand*)command;
- (void)onStart:(CDVInvokedUrlCommand*)command;
- (void)onStop:(CDVInvokedUrlCommand*)command;
- (void)trackEvent:(CDVInvokedUrlCommand*)command;
- (void)setUserCredentials:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;
- (void)logout:(CDVInvokedUrlCommand*)command;
- (void)setUserAttributes:(CDVInvokedUrlCommand*)command;
- (void)enablePush:(CDVInvokedUrlCommand*)command;
- (void)disablePush:(CDVInvokedUrlCommand*)command;
- (void)setDebugMode:(CDVInvokedUrlCommand*)command;
- (void)setKahunaCallback:(CDVInvokedUrlCommand*)command;

@end

@interface KahunaPushManager : NSObject
@property (nonatomic) NSDictionary *launchNotification;

+ (instancetype) sharedInstance;
- (void) didFinishLaunching:(NSNotification*) userInfo;

@end
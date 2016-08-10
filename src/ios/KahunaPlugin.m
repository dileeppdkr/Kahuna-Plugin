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
//  KahunaCordovaPlugin.m
//

#import "KahunaPlugin.h"
#import "Kahuna.h"
#import "KAHEventBuilder.h"

static NSString* const PUSH_TRACKING_KEY = @"k";
static NSString* const PUSH_APS_KEY = @"aps";
static NSString* const PUSH_APS_ALERT_KEY = @"alert";

@implementation KahunaPlugin

static NSString *secretKey;

// When this class loads we will register for the 'UIApplicationDidFinishLaunchingNotification' notification.
// To receive the notification we will use the KahunaPushManager singleton instance.
+ (void) load {
    [[NSNotificationCenter defaultCenter] addObserver:[KahunaPushManager sharedInstance]
                                             selector:@selector(didFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    
}

- (void)startWithKey:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* key = [command.arguments objectAtIndex:0];
    
    if (key != nil && [key length] > 0) {
        [Kahuna sharedInstance].delegate = self;
        [Kahuna setDeepIntegrationMode:true];
        [Kahuna setSDKWrapper:@"cordova" withVersion:@"2.3.1"];
        [Kahuna launchWithKey:key];
        secretKey = key;
        
        // If we have a launch Notification present, then call handleNotification with UIApplicationStateInactive so that we can process
        // the push clicked.
        if ([KahunaPushManager sharedInstance].launchNotification) {
            [Kahuna handleNotification:[KahunaPushManager sharedInstance].launchNotification withApplicationState:UIApplicationStateInactive];
            
            // Set the launchNotification to nil since we do not need it anymore.
            [KahunaPushManager sharedInstance].launchNotification = nil;
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Need non-nil & non-empty Secret Key."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)launchWithKey:(CDVInvokedUrlCommand*)command {
    [self startWithKey:command];
}

- (void)onStart:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    if (secretKey != nil && [secretKey length] > 0) {
        [Kahuna launchWithKey:secretKey];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Need non-nil & non-empty Secret Key to be set in onStart."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)onStop:(CDVInvokedUrlCommand*)command {
    // Not implemented in iOS since we have the observer already setup.
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)track:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* eventName = [command.arguments objectAtIndex:0];
    id count = [command.arguments objectAtIndex:1];
    id value = [command.arguments objectAtIndex:2];
    id eventProperties = [command.arguments objectAtIndex:3];

    if (!([count isKindOfClass:[NSNumber class]]) || !([value isKindOfClass:[NSNumber class]]) || !([eventProperties isKindOfClass:[NSDictionary class]])) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"track command can only accept a KahunaEvent object"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    NSDictionary *dictOfEventProperites = eventProperties;
    KAHEventBuilder *eventBuilder = [KAHEventBuilder eventWithName:eventName];
    [eventBuilder setPurchaseCount:[count longValue] andPurchaseValue:[value longValue]];
    for (NSString *key in dictOfEventProperites) {
        NSArray *aryProperties = dictOfEventProperites[key];
        if ([aryProperties isKindOfClass:[NSArray class]]) {
            for (NSString *eachProperty in aryProperties) {
                [eventBuilder addProperty:key withValue:eachProperty];
            }
        }
    }
    [Kahuna track:[eventBuilder build]];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)trackEvent:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* eventName = [command.arguments objectAtIndex:0];
    
    if (eventName != nil && [eventName length] > 0) {
        [Kahuna trackEvent:eventName];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Need non-nil & non-empty event name."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setUserCredentials:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString* username = [command.arguments objectAtIndex:0];
    NSString* email = [command.arguments objectAtIndex:1];
    
    KahunaUserCredentials *kah = [Kahuna getUserCredentials];
    [kah addCredential:KAHUNA_CREDENTIAL_USERNAME withValue:username];
    [kah addCredential:KAHUNA_CREDENTIAL_EMAIL withValue:email];
    NSError *error = nil;
    [Kahuna loginWithCredentials:kah error:&error];
    if (error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)login:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    id creds = [command.arguments objectAtIndex:0];
    if ([creds isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictOfCredentials = creds;
        KahunaUserCredentials *kah = [Kahuna createUserCredentials];
        
        for (NSString *key in dictOfCredentials) {
            NSArray *aryCreds = dictOfCredentials [key];
            if ([aryCreds isKindOfClass:[NSArray class]]) {
                for (NSString *eachCredential in aryCreds) {
                    [kah addCredential:key withValue:eachCredential];
                }
            }
        }
        
        NSError *error = nil;
        [Kahuna loginWithCredentials:kah error:&error];
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Login command can only accept a KahunaUserCredentials object"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)logout:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    
    [Kahuna logout];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setUserAttributes:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSDictionary *userAttributes = [command.arguments objectAtIndex:0];
    
    [Kahuna setUserAttributes:userAttributes];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)enablePush:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSDictionary *notificationOptions = [command.arguments objectAtIndex:0];
    
    NSUInteger notificationTypes = 0;
    id badgeArg = nil;
    id soundArg = nil;
    id alertArg = nil;
    
    if (notificationOptions && [notificationOptions isKindOfClass:[NSDictionary class]])
    {
        badgeArg = [notificationOptions objectForKey:@"badge"];
        soundArg = [notificationOptions objectForKey:@"sound"];
        alertArg = [notificationOptions objectForKey:@"alert"];
    }
    else
    {
        alertArg = @"true";
    }
    
    if ([badgeArg isKindOfClass:[NSString class]])
    {
        if ([badgeArg isEqualToString:@"true"])
            notificationTypes |= (1 << 0);
    }
    else if ([badgeArg boolValue])
        notificationTypes |= (1 << 0);
    
    if ([soundArg isKindOfClass:[NSString class]])
    {
        if ([soundArg isEqualToString:@"true"])
            notificationTypes |= (1 << 1);
    }
    else if ([soundArg boolValue])
        notificationTypes |= (1 << 1);
    
    if ([alertArg isKindOfClass:[NSString class]])
    {
        if ([alertArg isEqualToString:@"true"])
            notificationTypes |= (1 << 2);
    }
    else if ([alertArg boolValue])
        notificationTypes |= (1 << 2);
    
    if (notificationTypes == 0)
    {
        return;
    }
    
#ifdef NSFoundationVersionNumber_iOS_7_1
    // iOS 8 has a new way to register for notifications. This conditional code takes care of iOS 8 and
    // previous versions.
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
#endif
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disablePush:(CDVInvokedUrlCommand*)command {
    // Not implemented in iOS since the OS controls enabling/disabling push
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setDebugMode:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }
    
    [Kahuna setDebugMode:[value boolValue]];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setKahunaCallback:(CDVInvokedUrlCommand*)command {
    _callbackId = command.callbackId;
}

- (void) kahunaInAppMessageReceived:(NSString *)message withDictionary:(NSDictionary *)extras {
    if (_callbackId)
    {
        NSMutableDictionary *responseDataDic = [[NSMutableDictionary alloc] init];
        [responseDataDic setValue:extras forKey:@"extras"];
        [responseDataDic setValue:message forKey:@"message"];
        [responseDataDic setValue:@"inAppMessage" forKey:@"type"];
        
        CDVPluginResult *pluginResult = [ CDVPluginResult
                                         resultWithStatus: CDVCommandStatus_OK
                                         messageAsDictionary: responseDataDic
                                         ];
        
        pluginResult.keepCallback = [NSNumber numberWithBool:YES];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    }
}

- (void) kahunaPushMessageReceived:(NSString *)message withDictionary:(NSDictionary *)extras withApplicationState:(UIApplicationState)applicationState  {
    if (_callbackId)
    {
        NSMutableDictionary *responseDataDic = [[NSMutableDictionary alloc] init];
        [responseDataDic setValue:extras forKey:@"extras"];
        [responseDataDic setValue:message forKey:@"message"];
        [responseDataDic setValue:[NSNumber numberWithInt:applicationState] forKey:@"applicationState"];
        [responseDataDic setValue:@"pushMessage" forKey:@"type"];
        
        CDVPluginResult *pluginResult = [ CDVPluginResult
                                         resultWithStatus: CDVCommandStatus_OK
                                         messageAsDictionary: responseDataDic
                                         ];
        
        pluginResult.keepCallback = [NSNumber numberWithBool:YES];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
    }
}

@end

// This class is responsible for getting the 'UIApplicationDidFinishLaunchingNotification' notification. It is received by the
// method didFinishLaunching and it stores the 'UIApplicationLaunchOptionsRemoteNotificationKey' value in a local variable.
@implementation KahunaPushManager
@synthesize launchNotification;

+ (instancetype) sharedInstance {
    static KahunaPushManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KahunaPushManager alloc] init];
    });
    return instance;
}

- (void) didFinishLaunching:(NSNotification*) notificationPayload {
    NSDictionary *userInfo = notificationPayload.userInfo;
    if ([userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        self.launchNotification = [userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    }
}

@end

//
//  KochavaTracker (Flutter)
//
//  Copyright (c) 2020 - 2023 Kochava, Inc. All rights reserved.
//

#pragma mark - Import

#import "KochavaTrackerPlugin.h"

#pragma mark - Util

// Interface for the kochavaTrackerUtil
@interface KochavaTrackerUtil : NSObject

@end

// Common utility functions used by all of the wrappers.
// Any changes to the methods in here must be propagated to the other wrappers.
@implementation KochavaTrackerUtil

// Log a message to the console.
+ (void)log:(nonnull NSString *)message {
    NSLog(@"KVA/Tracker: %@", message);
}

// Attempts to read an NSDictionary and returns nil if not one.
+ (nullable NSDictionary *)readNSDictionary:(nullable id)valueId {
    return [[NSDictionary class] performSelector:@selector(kva_from:) withObject:valueId];
}

// Attempts to read an NSArray and returns nil if not one.
+ (nullable NSArray *)readNSArray:(nullable id)valueId {
    return [[NSArray class] performSelector:@selector(kva_from:) withObject:valueId];
}

// Attempts to read an NSNumber and returns nil if not one.
+ (nullable NSNumber *)readNSNumber:(nullable id)valueId {
    return [[NSNumber class] performSelector:@selector(kva_from:) withObject:valueId];
}

// Attempts to read an NSString and returns nil if not one.
+ (nullable NSString *)readNSString:(nullable id)valueId {
    return [NSString kva_from:valueId];
}

// Attempts to read an NSObject and returns nil if not one.
+ (nullable NSObject *)readNSObject:(nullable id)valueId {
    return [valueId isKindOfClass:NSNull.self] ? nil : valueId;
}

// Converts an NSNumber to a double with fallback to a default value.
+ (double)convertNumberToDouble:(nullable NSNumber *)number defaultValue:(double)defaultValue {
    if(number != nil) {
        return [number doubleValue];
    }
    return defaultValue;
}

// Converts an NSNumber to a bool with fallback to a default value.
+ (BOOL)convertNumberToBool:(nullable NSNumber *)number defaultValue:(BOOL)defaultValue {
    if(number != nil) {
        return [number boolValue];
    }
    return defaultValue;
}

// Converts the deeplink result into an NSDictionary.
+ (nonnull NSDictionary *)convertDeeplinkToDictionary:(nonnull KVADeeplink *)deeplink {
    NSObject *object = [deeplink kva_asForContext:KVAContext.host];
    return [object isKindOfClass:NSDictionary.class] ? (NSDictionary *)object : @{};
}

// Converts the install attribution result into an NSDictionary.
+ (nonnull NSDictionary *)convertInstallAttributionToDictionary:(nonnull KVAAttributionResult *)installAttribution {
    if (KVATracker.shared.startedBool) {
        NSObject *object = [installAttribution kva_asForContext:KVAContext.host];
        return [object isKindOfClass:NSDictionary.class] ? (NSDictionary *)object : @{};
    } else {
        return @{
                @"retrieved": @(NO),
                @"raw": @{},
                @"attributed": @(NO),
                @"firstInstall": @(NO),
        };
    }
}

// Converts the config result into an NSDictionary.
+ (nonnull NSDictionary *)convertConfigToDictionary:(nonnull KVATrackerConfig *)config {
    return @{
            @"consentGdprApplies": @(config.consentGDPRAppliesBool),
    };
}

// Serialize an NSDictionary into a json serialized NSString.
+ (nullable NSString *)serializeJsonObject:(nullable NSDictionary *)dictionary {
    return [NSString kva_stringFromJSONObject:dictionary prettyPrintBool:NO];
}

// Parse a json serialized NSString into an NSArray.
+ (nullable NSArray *)parseJsonArray:(nullable NSString *)string {
    NSObject *object = [string kva_serializedJSONObjectWithPrintErrorsBool:YES];
    return ([object isKindOfClass:NSArray.class] ? (NSArray *) object : nil);
}

// Parse a json serialized NSString into an NSDictionary.
+ (nullable NSDictionary *)parseJsonObject:(nullable NSString *)string {
    NSObject *object = [string kva_serializedJSONObjectWithPrintErrorsBool:YES];
    return [object isKindOfClass:NSDictionary.class] ? (NSDictionary *) object : nil;
}

// Parse a NSString into a NSURL and logs a warning on failure.
+ (nullable NSURL *)parseNSURL:(nullable NSString *)string {
    NSURL *url = [NSURL URLWithString:string];
    if (url == nil && string.length > 0) {
        [KochavaTrackerUtil log:@"Warn: parseNSURL invalid input, not a valid URL"];
    }
    return url;
}

// Builds and sends an event given an event info dictionary.
+ (void)buildAndSendEvent:(nullable NSDictionary *)eventInfo {
    if(eventInfo == nil) {
        return;
    }
    NSString *name = [KochavaTrackerUtil readNSString:eventInfo[@"name"]];
    NSDictionary *data = [KochavaTrackerUtil readNSDictionary:eventInfo[@"data"]];
    NSString *iosAppStoreReceiptBase64String = [KochavaTrackerUtil readNSString:eventInfo[@"iosAppStoreReceiptBase64String"]];
    if (name.length > 0) {
        KVAEvent *event = [[KVAEvent alloc] initCustomWithEventName:name];
        if (data != nil) {
            event.infoDictionary = data;
        }
        if (iosAppStoreReceiptBase64String.length > 0) {
            event.appStoreReceiptBase64EncodedString = iosAppStoreReceiptBase64String;
        }
        [event send];
    } else {
        [KochavaTrackerUtil log:@"Warn: sendEventWithEvent invalid input"];
    }
}

@end

#pragma mark - Methods

@implementation KochavaTrackerPlugin

// Set the logging parameters before any other access to the SDK.
+ (void) initialize {
    KVALog.shared.osLogEnabledBool = false;
    KVALog.shared.printLinesIndividuallyBool = true;
}

// Register plugin with Flutter.
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"kochava_tracker" binaryMessenger:[registrar messenger]];
    KochavaTrackerPlugin *instance = [[KochavaTrackerPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

// Initialize the plugin with the method channel to communicate with Dart.
- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
    }
    return self;
}

// Handle a method call from the Dart layer.
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {

    // void executeAdvancedInstruction(string name, string value)
    if ([@"executeAdvancedInstruction" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSString *value = [KochavaTrackerUtil readNSString:valueDictionary[@"value"]];
        
        [KVATracker.shared.networking executeAdvancedInstructionWithUniversalIdentifier:name parameter:value prerequisiteTaskIdentifierArray:nil];
        result(@"success");

    // void setLogLevel(LogLevel logLevel)
    } else if ([@"setLogLevel" isEqualToString:call.method]) {
        NSString *logLevel = [KochavaTrackerUtil readNSString:call.arguments];
        
        KVALog.shared.level = [KVALogLevel kva_from:logLevel];
        result(@"success");

    // void setSleep(bool sleep)
    } else if ([@"setSleep" isEqualToString:call.method]) {
        BOOL sleep = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:false];
        
        KVATracker.shared.sleepBool = sleep;
        result(@"success");

    // void setAppLimitAdTracking(bool appLimitAdTracking)
    } else if ([@"setAppLimitAdTracking" isEqualToString:call.method]) {
        BOOL appLimitAdTracking = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:false];
        KVATracker.shared.appLimitAdTracking.boolean = appLimitAdTracking;
        result(@"success");

    // void registerCustomDeviceIdentifier(string name, string value)
    } else if ([@"registerCustomDeviceIdentifier" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSString *value = [KochavaTrackerUtil readNSString:valueDictionary[@"value"]];
        
        [KVATracker.shared.customIdentifiers registerWithName:name identifier:value];
        result(@"success");

    // void registerCustomStringValue(string, string value)
    } else if ([@"registerCustomStringValue" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSString *value = [KochavaTrackerUtil readNSString:valueDictionary[@"value"]];
        
        [KVACustomValue registerWithName:name value:value];
        result(@"success");

    // void registerCustomBoolValue(string, bool value)
    } else if ([@"registerCustomBoolValue" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSNumber *value = [KochavaTrackerUtil readNSNumber:valueDictionary[@"value"]];
        
        [KVACustomValue registerWithName:name value:value];
        result(@"success");

    // void registerCustomNumberValue(string, number value)
    } else if ([@"registerCustomNumberValue" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSNumber *value = [KochavaTrackerUtil readNSNumber:valueDictionary[@"value"]];
        
        [KVACustomValue registerWithName:name value:value];
        result(@"success");

    // void registerIdentityLink(string name, string value)
    } else if ([@"registerIdentityLink" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSString *value = [KochavaTrackerUtil readNSString:valueDictionary[@"value"]];

        [KVATracker.shared.identityLink registerWithName:name identifier:value];
        result(@"success");

    // void enableAndroidInstantApps(string instantAppGuid)
    } else if ([@"enableAndroidInstantApps" isEqualToString:call.method]) {
        [KochavaTrackerUtil log:@"enableAndroidInstantApps API is not available on this platform."];
        result(@"success");

    // void enableIosAppClips(string identifier)
    } else if ([@"enableIosAppClips" isEqualToString:call.method]) {
        NSString *identifier = [KochavaTrackerUtil readNSString:call.arguments];
        
        KVAAppGroups.shared.deviceAppGroupIdentifier = identifier;
        result(@"success");

    // void enableIosAtt()
    } else if ([@"enableIosAtt" isEqualToString:call.method]) {
        KVATracker.shared.appTrackingTransparency.enabledBool = true;
        result(@"success");

    // void setIosAttAuthorizationWaitTime(double waitTime)
    } else if ([@"setIosAttAuthorizationWaitTime" isEqualToString:call.method]) {
        double waitTime = [KochavaTrackerUtil convertNumberToDouble:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:30.0];
        
        KVATracker.shared.appTrackingTransparency.authorizationStatusWaitTimeInterval = waitTime;
        result(@"success");

    // void setIosAttAuthorizationAutoRequest(bool autoRequest)
    } else if ([@"setIosAttAuthorizationAutoRequest" isEqualToString:call.method]) {
        BOOL autoRequest = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:true];
        
        KVATracker.shared.appTrackingTransparency.autoRequestTrackingAuthorizationBool = autoRequest;
        result(@"success");

    // void registerPrivacyProfile(string name, string[] keys)
    } else if ([@"registerPrivacyProfile" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSArray *keys = [KochavaTrackerUtil readNSArray:valueDictionary[@"keys"]];

        [KVAPrivacyProfile registerWithName:name payloadKeyStringArray:keys];
        result(@"success");

    // void setPrivacyProfileEnabled(string name, bool enabled)
    } else if ([@"setPrivacyProfileEnabled" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        BOOL enabled = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:valueDictionary[@"enabled"]] defaultValue:false];

        [KVATracker.shared.privacy setEnabledBoolForProfileName:name enabledBool:enabled];
        result(@"success");

    // void setInitCompletedListener(bool setListener)
    } else if ([@"setInitCompletedListener" isEqualToString:call.method]) {
        BOOL setListener = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:true];

        if(setListener) {
            KVATracker.shared.config.closure_didComplete = ^(KVATrackerConfig * _Nonnull config)
            {
                NSDictionary *configDictionary = [KochavaTrackerUtil convertConfigToDictionary:config];
                NSString *configString = [KochavaTrackerUtil serializeJsonObject:configDictionary] ?: @"{}";
                [self.channel invokeMethod:@"initCompletedCallback" arguments:configString];
            };
        } else {
            KVATracker.shared.config.closure_didComplete = nil;
        }
        result(@"success");

    // void setIntelligentConsentGranted(bool granted)
    } else if ([@"setIntelligentConsentGranted" isEqualToString:call.method]) {
        NSNumber *granted = [KochavaTrackerUtil readNSNumber:call.arguments];

        KVATracker.shared.privacy.intelligentConsent.grantedBoolNumber = granted;
        result(@"success");

    // bool getStarted()
    } else if ([@"getStarted" isEqualToString:call.method]) {
        result(@(KVATracker.shared.startedBool));

    // void start(string androidAppGuid, string iosAppGuid, string partnerName)
    } else if ([@"start" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *iosAppGuid = [KochavaTrackerUtil readNSString:valueDictionary[@"iosAppGuid"]];
        NSString *partnerName = [KochavaTrackerUtil readNSString:valueDictionary[@"partnerName"]];

        if(iosAppGuid.length > 0) {
            [KVATracker.shared startWithAppGUIDString:iosAppGuid];
        } else if(partnerName.length > 0) {
            [KVATracker.shared startWithPartnerNameString:partnerName];
        } else {
            // Allow the native to log the error of no app guid.
            [KVATracker.shared startWithAppGUIDString:nil];
        }

        result(@"success");

    // void shutdown(bool deleteData)
    } else if ([@"shutdown" isEqualToString:call.method]) {
        BOOL deleteData = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:false];

        [KVATrackerProduct.shared shutdownWithDeleteLocalDataBool:deleteData];
        result(@"success");

    // string getDeviceId()
    } else if ([@"getDeviceId" isEqualToString:call.method]) {
        if(KVATracker.shared.startedBool) {
            result(KVATracker.shared.deviceId.string ?: @"");
        } else {
            result(@"");
        }

    // InstallAttribution getInstallAttribution()
    } else if ([@"getInstallAttribution" isEqualToString:call.method]) {
        NSDictionary *attributionDictionary = [KochavaTrackerUtil convertInstallAttributionToDictionary:KVATracker.shared.attribution.result];
        NSString *attributionString = [KochavaTrackerUtil serializeJsonObject:attributionDictionary] ?: @"";
        result(attributionString);

    // void retrieveInstallAttribution(Callback<InstallAttribution> callback)
    } else if ([@"retrieveInstallAttribution" isEqualToString:call.method]) {
        [KVATracker.shared.attribution retrieveResultWithCompletionHandler:^(KVAAttributionResult * attribution) {
            NSDictionary *attributionDictionary = [KochavaTrackerUtil convertInstallAttributionToDictionary:attribution];
            NSString *attributionString = [KochavaTrackerUtil serializeJsonObject:attributionDictionary] ?: @"";
            result(attributionString);
        }];

    // void processDeeplink(string path, Callback<Deeplink> callback)
    } else if ([@"processDeeplink" isEqualToString:call.method]) {
        NSURL *path = [KochavaTrackerUtil parseNSURL:call.arguments ?: @""];
        
        [KVADeeplink processWithURL:path closure_didComplete:^(KVADeeplink *_Nonnull deeplink) {
            NSDictionary *deeplinkDictionary = [KochavaTrackerUtil convertDeeplinkToDictionary:deeplink];
            NSString *deeplinkString = [KochavaTrackerUtil serializeJsonObject:deeplinkDictionary] ?: @"";
            result(deeplinkString);
        }];

    // void processDeeplinkWithOverrideTimeout(string path, double timeout, Callback<Deeplink> callback)
    } else if ([@"processDeeplinkWithOverrideTimeout" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSURL *path = [KochavaTrackerUtil parseNSURL:[KochavaTrackerUtil readNSString:valueDictionary[@"path"]]];
        double timeout = [KochavaTrackerUtil convertNumberToDouble:[KochavaTrackerUtil readNSNumber:valueDictionary[@"timeout"]] defaultValue:10.0];
        
        [KVADeeplink processWithURL:path timeoutTimeInterval:timeout closure_didComplete:^(KVADeeplink *_Nonnull deeplink) {
            NSDictionary *deeplinkDictionary = [KochavaTrackerUtil convertDeeplinkToDictionary:deeplink];
            NSString *deeplinkString = [KochavaTrackerUtil serializeJsonObject:deeplinkDictionary] ?: @"";
            result(deeplinkString);
        }];

    // void registerPushToken(string token)
    } else if ([@"registerPushToken" isEqualToString:call.method]) {
        NSString *token = [KochavaTrackerUtil readNSString:call.arguments];
        [KVAPushNotificationsToken registerWithDataHexString:token];
        result(@"success");

    // void setPushEnabled(bool enabled)
    } else if ([@"setPushEnabled" isEqualToString:call.method]) {
        BOOL enabled = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:call.arguments] defaultValue:true];
        KVATracker.shared.pushNotifications.enabledBool = enabled;
        result(@"success");

    // void registerDefaultEventStringParameter(string, string value)
    } else if ([@"registerDefaultEventStringParameter" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSString *value = [KochavaTrackerUtil readNSString:valueDictionary[@"value"]];
        
        [KVAEventDefaultParameter registerWithName:name value:value];
        result(@"success");

    // void registerDefaultEventBoolParameter(string, bool value)
    } else if ([@"registerDefaultEventBoolParameter" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSNumber *value = [KochavaTrackerUtil readNSNumber:valueDictionary[@"value"]];
        
        [KVAEventDefaultParameter registerWithName:name value:value];
        result(@"success");

    // void registerDefaultEventNumberParameter(string, number value)
    } else if ([@"registerDefaultEventNumberParameter" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSNumber *value = [KochavaTrackerUtil readNSNumber:valueDictionary[@"value"]];
        
        [KVAEventDefaultParameter registerWithName:name value:value];
        result(@"success");

    // void registerDefaultEventUserId(string value)
    } else if ([@"registerDefaultEventUserId" isEqualToString:call.method]) {
        NSString *value = [KochavaTrackerUtil readNSString:call.arguments];

        [KVAEventDefaultParameter registerWithUserIdString:value];
        result(@"success");

    // void sendEvent(string name)
    } else if ([@"sendEvent" isEqualToString:call.method]) {
        NSString *name = [KochavaTrackerUtil readNSString:call.arguments];
        
        if (name.length > 0) {
            [KVAEvent sendCustomWithEventName:name];
        } else {
            [KochavaTrackerUtil log:@"Warn: sendEvent invalid input"];
        }
        result(@"success");

    // void sendEventWithString(string name, string data)
    } else if ([@"sendEventWithString" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSString *data = [KochavaTrackerUtil readNSString:valueDictionary[@"data"]];
        
        if (name.length > 0) {
            [KVAEvent sendCustomWithEventName:name infoString:data];
        } else {
            [KochavaTrackerUtil log:@"Warn: sendEventWithString invalid input"];
        }
        result(@"success");

    // void sendEventWithDictionary(string name, object data)
    } else if ([@"sendEventWithDictionary" isEqualToString:call.method]) {
        NSDictionary *valueDictionary = [KochavaTrackerUtil readNSDictionary:call.arguments] ?: @{};
        NSString *name = [KochavaTrackerUtil readNSString:valueDictionary[@"name"]];
        NSDictionary *data = [KochavaTrackerUtil readNSDictionary:valueDictionary[@"data"]];
        
        if (name.length > 0) {
            [KVAEvent sendCustomWithEventName:name infoDictionary:data];
        } else {
            [KochavaTrackerUtil log:@"Warn: sendEventWithString invalid input"];
        }
        result(@"success");

    // void sendEventWithEvent(Event event)
    } else if ([@"sendEventWithEvent" isEqualToString:call.method]) {
        NSDictionary *eventInfo = [KochavaTrackerUtil readNSDictionary:call.arguments];
        [KochavaTrackerUtil buildAndSendEvent:eventInfo];
        result(@"success");

    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end

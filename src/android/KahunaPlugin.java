/*
 * Kahuna CONFIDENTIAL
 * __________________
 *
 *  2014-2015 Kahuna, Inc.
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
package com.kahuna.phonegap.sdk;

import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;
import java.util.Map;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.kahuna.sdk.EmptyCredentialsException;
import com.kahuna.sdk.Event;
import com.kahuna.sdk.EventBuilder;
import com.kahuna.sdk.IKahunaUserCredentials;
import com.kahuna.sdk.Kahuna;
import com.kahuna.sdk.KahunaInAppMessageListener;
import com.kahuna.sdk.KahunaUserCredentials;

public class KahunaPlugin extends CordovaPlugin {

    private static final String TAG = "Kahuna";

    private static final String START_WITH_KEY = "startWithKey";
    private static final String LAUNCH_WITH_KEY = "launchWithKey";
    private static final String ON_START = "onStart";
    private static final String ON_STOP = "onStop";
    private static final String TRACK_EVENT = "trackEvent";
    private static final String TRACK = "track";
    private static final String SET_USER_CREDENTIALS = "setUserCredentials";
    private static final String LOGIN = "login";
    private static final String LOGOUT = "logout";
    private static final String SET_USER_ATTRIBUTES = "setUserAttributes";
    private static final String ENABLE_PUSH = "enablePush";
    private static final String DISABLE_PUSH = "disablePush";
    private static final String SET_DEBUG_MODE = "setDebugMode";
    private static final String SET_KAHUNA_CALLBACK = "setKahunaCallback";
    private static final String CORDOVA_SDK_VERSION = "2.3.2";

    private static String callbackId;
    private static CordovaWebView cordovaWebView;
    private PlugInAppMessageListener plugInAppMessageListener = new PlugInAppMessageListener();
    private static boolean pluginDebugEnabled = false;
    private static JSONObject pendingPushResponse = null;

    static {
        Kahuna.getInstance().setPushReceiver(KAPushReceiver.class);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {

        try {
            if (START_WITH_KEY.equals(action) || LAUNCH_WITH_KEY.equals(action)) {
                String secretKey = args.getString(0);
                String senderId = null;

                if (args.length() > 1) {
                    senderId = args.getString(1);
                }

                this.startWithKey(secretKey, senderId);
                return true;
            } else if (ON_START.equals(action)) {
                this.onKahunaStart();
                return true;
            } else if (ON_STOP.equals(action)) {
                this.onKahunaStop();
                return true;
            } else if (TRACK.equals(action)) {
            	if(args.length() != 4) {
            		Log.e(TAG, "Execute " + action + " does not have enough arguments. Number of arguments was: " + args.length());
            		return true;
            	}
                String eventName = args.getString(0);
                int count = args.optInt(1, -1);
                int value = args.optInt(2, -1);
                JSONObject eventProperties = args.optJSONObject(3);
                
                EventBuilder eb = new EventBuilder(eventName);
                eb.setPurchaseData(count, value);
                Iterator<String> keys = eventProperties.keys();
				while (keys.hasNext()) {
					String key = keys.next();
					JSONArray valueArray = eventProperties.optJSONArray(key);
					if (valueArray != null) {
						int arrayLength = valueArray.length();
						for (int i = 0; i < arrayLength; i++) {
							eb.addProperty(key, valueArray.optString(i));
						}
					}
				}
                this.track(eb.build());
                return true;
            }
            else if (TRACK_EVENT.equals(action)) {
                String eventName = args.getString(0);
                this.trackEvent(eventName);
                return true;
            } else if (SET_USER_ATTRIBUTES.equals(action)) {
                Map<String, String> userAttributes = null;
                JSONObject userAttsObject = args.getJSONObject(0);
                userAttributes = new HashMap<String, String>();
                Iterator<?> keys = userAttsObject.keys();
                while (keys.hasNext()) {
                    String key = (String) keys.next();
                    userAttributes.put(key, userAttsObject.getString(key));
                }
                this.setUserAttributes(userAttributes);
                return true;
            } else if (SET_USER_CREDENTIALS.equals(action)) {
                String username = args.getString(0);
                String email = args.getString(1);
                this.setUserCredentials(username, email);
                return true;
            } else if (LOGIN.equals(action)) {
                String jsonString = args.getString(0);
                JSONObject jsonObject = new JSONObject(jsonString);

                if (jsonObject.keys() != null) {
                    IKahunaUserCredentials newCreds = Kahuna.getInstance().createUserCredentials();

                    Iterator<String> keys = jsonObject.keys();
                    while (keys.hasNext()) {
                        String key = keys.next();

                        // could be array or string;
                        JSONArray valueArray = jsonObject.optJSONArray(key);
                        if (valueArray != null) {
                            for (int i = 0; i < valueArray.length(); i++) {
                                newCreds.add(key, valueArray.optString(i));
                            }

                        } else {
                            String valueString = jsonObject.optString(key);
                            newCreds.add(key, valueString);
                        }
                    }

                    this.login(newCreds);
                    return true;
                }
                else {
                    Log.e(TAG, "You must specify a KahunaUserCredentials object when using the login method.");
                }
                return false;
            } else if (LOGOUT.equals(action)) {
                this.logout();
                return true;
            } else if (ENABLE_PUSH.equals(action)) {
                this.enablePush();
                return true;
            } else if (DISABLE_PUSH.equals(action)) {
                this.disablePush();
                return true;
            } else if (SET_DEBUG_MODE.equals(action)) {
                boolean enabled = args.getBoolean(0);
                this.setDebugMode(enabled);
                pluginDebugEnabled = enabled;
                return true;
            } else if (SET_KAHUNA_CALLBACK.equals(action)) {
                callbackId = callbackContext.getCallbackId();
                cordovaWebView = this.webView;
                // If there is a pending push clicked, let's notify the JS layer
                // now.
                if (pendingPushResponse != null) {
                    notifyCallbackResponseData(callbackId, cordovaWebView, pendingPushResponse);
                    pendingPushResponse = null;
                }
                return true;
            } else {
                Log.w(TAG, "Execute " + action + " did no match any method definition defined by Kahuna.");
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        cordovaWebView = null;
        callbackId = null;
        pendingPushResponse = null;
    }

    private void startWithKey(final String secretKey, final String senderId) {
        Kahuna.getInstance().onAppCreate(this.cordova.getActivity().getApplicationContext(), secretKey, senderId);
        Kahuna.getInstance().setHybridSDKVersion("cordova", CORDOVA_SDK_VERSION);
        Kahuna.getInstance().start();
        // Register the InAppMessageListner. This class instance's method will
        // be called when we receive an In App message.
        Kahuna.getInstance().registerInAppMessageListener(plugInAppMessageListener);
    }

    private void onKahunaStart() {
        Kahuna.getInstance().start();
    }

    private void onKahunaStop() {
        Kahuna.getInstance().stop();
    }
    
    private void track(final Event eventObject) {
    	Kahuna.getInstance().track(eventObject);
    }

    private void trackEvent(final String eventName) {
        Kahuna.getInstance().trackEvent(eventName);
    }

    private void setUserCredentials(final String username, final String email) {
        IKahunaUserCredentials newCreds = Kahuna.getInstance().getUserCredentials();
        if (username != null)
            newCreds.add(KahunaUserCredentials.USERNAME_KEY, username);
        if (email != null)
            newCreds.add(KahunaUserCredentials.EMAIL_KEY, email);
        login(newCreds);
    }

    private void login(IKahunaUserCredentials newCreds) {
        try {
            Kahuna.getInstance().login(newCreds);
        } catch (EmptyCredentialsException e) {
            Log.e(TAG, "Caught Exception while login + " + e);
            Log.w(TAG, "Please make sure the KahunaUserCredentials object has values before using login. An empty KahunaUserCredentials object is tracked as a logout.");
        }
    }

    private void logout() {
        Kahuna.getInstance().logout();
    }

    private void setUserAttributes(Map<String, String> userAttributes) {
        Kahuna.getInstance().setUserAttributes(userAttributes);
    }

    private void enablePush() {
        Kahuna.getInstance().enablePush();
    }

    private void disablePush() {
        Kahuna.getInstance().disablePush();
    }

    private void setDebugMode(boolean enable) {
        Kahuna.getInstance().setDebugMode(enable);
    }

    private static final Object NULL = new Object() {
        @Override
        public boolean equals(Object o) {
            return o == this || o == null; // API specifies this broken equals
                                           // implementation
        }

        @Override
        public String toString() {
            return "null";
        }
    };

    private static Object wrap(Object o) {
        if (o == null) {
            return NULL;
        }
        if (o instanceof JSONArray || o instanceof JSONObject) {
            return o;
        }
        if (o.equals(NULL)) {
            return o;
        }
        try {
            if (o instanceof Collection) {
                return new JSONArray((Collection) o);
            }
            if (o instanceof Map) {
                return new JSONObject((Map) o);
            }
            if (o instanceof Boolean || o instanceof Byte || o instanceof Character || o instanceof Double
                    || o instanceof Float || o instanceof Integer || o instanceof Long || o instanceof Short
                    || o instanceof String) {
                return o;
            }
            if (o.getClass().getPackage().getName().startsWith("java.")) {
                return o.toString();
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private static JSONObject bundleToJSONObject(Bundle bundle) {
        JSONObject json = new JSONObject();
        Set<String> keys = bundle.keySet();
        for (String key : keys) {
            try {
                json.put(key, KahunaPlugin.wrap(bundle.get(key)));
            } catch (JSONException e) {
                // Do nothing. This key will not get added to the JSONObject
            }
        }
        return json;
    }

    private static void notifyCallbackResponseData(String callbackId, CordovaWebView webview, JSONObject responseData) {
        PluginResult pluginResult = new PluginResult(Status.OK, responseData);
        pluginResult.setKeepCallback(true);

        CallbackContext callbackResponseData = new CallbackContext(callbackId, webview);
        callbackResponseData.sendPluginResult(pluginResult);
    }

    public static class KahunaCordovaCoreReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            // We may need to actually defer processing of Push messages here
            // entirely
            // in a future version, but for now this will ensure our plugin sets
            // the Push
            // receiver if a Push happens to wake up the host app and it wasn't
            // running.
            Kahuna.getInstance().setPushReceiver(KAPushReceiver.class);
        }

    }

    public static class KAPushReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            try {
                String action = intent.getAction();
                if (Kahuna.ACTION_PUSH_CLICKED.equals(action)) {
                    /* Push notification was clicked. */
                    Bundle extras = intent.getBundleExtra(Kahuna.EXTRA_LANDING_DICTIONARY_ID);
                    String message = extras.getString(Kahuna.EXTRA_PUSH_MESSAGE);
                    if (pluginDebugEnabled) {
                        Log.i(TAG, "User Clicked on Kahuna Push");

                        for (String key : extras.keySet()) {
                            Object value = extras.get(key);
                            Log.d(TAG, String.format("%s : %s (%s)", key, value.toString(), value.getClass().getName()));
                        }
                    }

                    JSONObject extrasJson = KahunaPlugin.bundleToJSONObject(extras);
                    JSONObject responseJsonData = new JSONObject();

                    responseJsonData.put("extras", extrasJson);
                    responseJsonData.put("type", "pushMessage");
                    responseJsonData.put("message", message);

                    if (callbackId != null) {
                        notifyCallbackResponseData(callbackId, cordovaWebView, responseJsonData);
                        pendingPushResponse = null;
                    } else {
                        // If the app wasn't in memory fully when the push got
                        // clicked, let's defer the callback
                        // until start with key to deliver it.
                        pendingPushResponse = responseJsonData;
                    }
                }
                if (Kahuna.ACTION_PUSH_RECEIVED.equals(action)) {
                    /* Push notification was received. */
                    if (pluginDebugEnabled) {
                        Log.i(TAG, "Received Kahuna push");

                        Bundle extras = intent.getBundleExtra(Kahuna.EXTRA_LANDING_DICTIONARY_ID);
                        for (String key : extras.keySet()) {
                            Object value = extras.get(key);
                            Log.d(TAG, String.format("%s : %s (%s)", key, value.toString(), value.getClass().getName()));
                        }
                    }
                }
            } catch (JSONException e) {
                Log.e(TAG, "Caught exception processing Push: " + e);
            }
        }
    }

    public class PlugInAppMessageListener implements KahunaInAppMessageListener {

        @Override
        public void onInAppMessageReceived(String message, Bundle deepLinkingExtras) {
            try {
                if (callbackId != null) {

                    JSONObject extrasJson = KahunaPlugin.bundleToJSONObject(deepLinkingExtras);
                    JSONObject responseJsonData = new JSONObject();

                    if (pluginDebugEnabled) {
                        Log.i(TAG, "Received Kahuna In-App Message");

                        Log.d(TAG, "message: " + message);
                        Log.d(TAG, "extras: " + extrasJson);
                    }

                    responseJsonData.put("extras", extrasJson);
                    responseJsonData.put("type", "inAppMessage");
                    responseJsonData.put("message", message);
                    notifyCallbackResponseData(callbackId, cordovaWebView, responseJsonData);
                }
            } catch (JSONException e) {
                Log.e(TAG, "Caught exception processing In-App Message: " + e);
            }
        }
    };
}

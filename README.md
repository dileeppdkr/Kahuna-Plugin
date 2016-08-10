# Kahuna-Plugin
Kahuna Plugin for Cordova/PhoneGap

Requirements - The Kahuna Plugin currently supports Cordova 3.0+ and functions with the iOS and Android platforms only.
First, get the Kahuna Plugin into your app.

If you have not upgraded to the latest Cordova SDK, you should still continue using your 2 Secret Keys to distinguish Sandbox vs Production data. The latest Android, iOS and Cordova SDKs now use a single Secret Key scheme which is reflected in the instructions below.

[Download the Kahuna Cordova Plugin here.](storage.googleapis.com/kahuna-mobile-public/kahuna_cordovasdk_2.3.2.zip)

OR

1. Add the Kahuna plugin to your project.
```sh
  cordova plugin add kahuna-plugin
```


####Now, what data do you have on the people who use your app?

#### Your app allows some form of user login and/or registration. Some users can continue to use your app anonymously if they want.

2. Bind the 'deviceready', 'pause' and 'resume' event listeners in your index.js file:

```sh
  bindEvents: function() {
      document.addEventListener('deviceready', this.onDeviceReady, false);
      document.addEventListener('pause', this.onPaused, false);
      document.addEventListener('resume', this.onResume, false);
  }
```
3. Incorporate the following lines in your onDeviceReady() callback function.:

##### May have Username/Email


```sh
  onDeviceReady: function() {
      app.receivedEvent('deviceready');
      Kahuna.launchWithKey('3f112b20c2a2445d8a9a271b6fb40591');
      var credentials = KahunaUserCredentials();
      credentials.add(KahunaUserCredentials().USERNAME_KEY, USERNAME_HERE);
      credentials.add(KahunaUserCredentials().EMAIL_KEY, EMAIL_HERE);
      Kahuna.login(credentials);
  }
```


##### May have Other Credentials


```sh
  onDeviceReady: function() {
    app.receivedEvent('deviceready');
    Kahuna.launchWithKey('3f112b20c2a2445d8a9a271b6fb40591');
    var credentials = KahunaUserCredentials();
    credentials.add(KahunaUserCredentials().USER_ID_KEY, USER_ID_HERE);
    credentials.add(KahunaUserCredentials().USERNAME_KEY, USERNAME_HERE);
    credentials.add(KahunaUserCredentials().EMAIL_KEY, EMAIL_HERE);
    credentials.add(KahunaUserCredentials().FACEBOOK_KEY, FACEBOOK_ID_HERE);
    credentials.add(KahunaUserCredentials().TWITTER_KEY, TWITTER_ID_HERE);
    credentials.add(KahunaUserCredentials().LINKEDIN_KEY, LINKEDIN_ID_HERE);
    credentials.add(KahunaUserCredentials().GOOGLE_PLUS_ID, GOOGLE_PLUS_ID_HERE);
    credentials.add(KahunaUserCredentials().INSTALL_TOKEN_KEY, INSTALL_TOKEN_HERE);
    Kahuna.login(credentials);
  }
```

##### Anonymous only

```sh
  onDeviceReady: function() {
      app.receivedEvent('deviceready');
      Kahuna.launchWithKey('3f112b20c2a2445d8a9a271b6fb40591');
  }
```




4. Finally, call Kahuna.onStop() and Kahuna.onStart() in the paused and resume callback functions as shown below:
```sh
  onPaused: function() {
    Kahuna.onStop();
  }

  onResume: function() {
      Kahuna.onStart();
  }    
```

#### After you've done that, launch your app. We'll wait for you to verify.
#### Waiting for app start...

5. Since you've incorporated user credentials into your app, you will need to tell Kahuna when the user logs out of your app. You can do that with the following:
```sh
  Kahuna.logout();
 ```
 
 
 The Kahuna Plugin supports sending targeted push notifications for both iOS and Android Platforms! Follow these steps to get it hooked up in your app after you have done the basic integration.
 
 * Generate your CSR - show me
 * Generate Push SSL Certificate - show me
 * Upload Push Certificate to Kahuna - show me
 * Integrate Call to prompt user to Enable Push - To support Push in your iOS application, you must prompt the user using the following call : (Note: Push must be tested on an actual device, it will not work in the iOS simulator)

```sh
onDeviceReady: function() {
    app.receivedEvent('deviceready');
    Kahuna.launchWithKey('KEY');
    Kahuna.enablePush();
}
 ```
 
 
You may make the call to enable Push at any point in your application to prompt the user.

#### Push Callback Mechanism

Setup callback function for receiving push messages.
Implement function 'kahunaCallback' as shown below. Add this function outside the 'app' object of your index.js file. 

```sh                        
 function kahunaCallback (payload) {
    var type = payload['type']; // For push messages this value will be 'pushMessage'
    var message = payload['message']; // The push message.
    var extras = payload['extras']; // Deep link parameters associated with the Push.
    var applicationState = payload['applicationState']; // iOS Only. State of the application. 0:Active, 1:InActive, 2:Background.
    if (type == 'pushMessage') {
        alert ('push message ' + message + ' received');
    }
};
 ```
 
 
 Register the 'kahunaCallback' callback function inside onDeviceReady as shown below.
```sh 
Kahuna.setKahunaCallback(kahunaCallback);
 ```
 
                        

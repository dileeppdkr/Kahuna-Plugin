# Kahuna-Plugin
Kahuna Plugin for Cordova/PhoneGap

Requirements - The Kahuna Plugin currently supports Cordova 3.0+ and functions with the iOS and Android platforms only.
First, get the Kahuna Plugin into your app.

If you have not upgraded to the latest Cordova SDK, you should still continue using your 2 Secret Keys to distinguish Sandbox vs Production data. The latest Android, iOS and Cordova SDKs now use a single Secret Key scheme which is reflected in the instructions below.


1. Add the Kahuna plugin to your project.
cordova plugin add kahuna-plugin


Now, what data do you have on the people who use your app?

Your app allows some form of user login and/or registration. Some users can continue to use your app anonymously if they want.

2. Bind the 'deviceready', 'pause' and 'resume' event listeners in your index.js file:


  bindEvents: function() {
      document.addEventListener('deviceready', this.onDeviceReady, false);
      document.addEventListener('pause', this.onPaused, false);
      document.addEventListener('resume', this.onResume, false);
  }


3. Incorporate the following lines in your onDeviceReady() callback function.:


  onDeviceReady: function() {
      app.receivedEvent('deviceready');
      Kahuna.launchWithKey('3f112b20c2a2445d8a9a271b6fb40591');
      var credentials = KahunaUserCredentials();
      credentials.add(KahunaUserCredentials().USERNAME_KEY, USERNAME_HERE);
      credentials.add(KahunaUserCredentials().EMAIL_KEY, EMAIL_HERE);
      Kahuna.login(credentials);
  }

4. Finally, call Kahuna.onStop() and Kahuna.onStart() in the paused and resume callback functions as shown below:
  onPaused: function() {
    Kahuna.onStop();
  }

  onResume: function() {
      Kahuna.onStart();
  }                      
                        

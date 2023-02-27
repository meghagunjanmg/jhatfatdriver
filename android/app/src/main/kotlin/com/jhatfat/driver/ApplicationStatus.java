package com.jhatfat.driver;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService;

public class ApplicationStatus extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {

    @Override
    public void onCreate() {
        super.onCreate();
        FirebaseOptions options = new FirebaseOptions.Builder()
                .setApplicationId("com.jhatfat.driver") // Required for Analytics.
                .setProjectId("jhatfatdriver") // Required for Firebase Installations.
                .setApiKey("AIzaSyC_Kc_e3pY9ZgMmM6Wd90Yw6WzHthW7Prw") // Required for Auth.
                .build();
        FirebaseApp.initializeApp(this,options,"jhatfatdriver");
        FlutterFirebaseMessagingService.setPluginRegistrant(this);
    }

    @Override
    public void registerWith(PluginRegistry registry) {
        FirebaseCloudMessagingPluginRegistrant.registerWith(registry);
    }
}

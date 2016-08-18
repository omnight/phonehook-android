package com.omnight.phonehook;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class ServiceStarter extends BroadcastReceiver {

    private static final String TAG = "Phonehook";

    @Override
    public void onReceive(Context context, Intent intent) {

        Log.d(TAG, "receive broadcast");

        Intent myIntent = new Intent(context, MyService.class);
        context.startService(myIntent);

    }
}

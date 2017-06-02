package com.omnight.phonehook;

import android.telephony.TelephonyManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class ServiceStarter extends BroadcastReceiver {

    private static final String TAG = "Phonehook";

    @Override
    public void onReceive(Context context, Intent intent) {

        Log.d(TAG, "receive broadcast");


        String str = intent.getAction();

        if(Intent.ACTION_BOOT_COMPLETED.equals(str)) {
            Intent myIntent = new Intent(context, MyService.class);
            context.startService(myIntent);
        }


        if(TelephonyManager.ACTION_PHONE_STATE_CHANGED.equals(str)) {

            String callState = intent.getStringExtra(TelephonyManager.EXTRA_STATE);

            if (TelephonyManager.EXTRA_STATE_RINGING.equals(callState)) {
                final String incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER);
                Intent myIntent = new Intent(context, MyService.class);
                myIntent.putExtra("incomingNumber", incomingNumber);

                context.startService(myIntent);
            }
        }
    }
}

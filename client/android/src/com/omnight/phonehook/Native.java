package com.omnight.phonehook;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Presentation;
import android.app.TaskStackBuilder;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.database.Cursor;
import android.net.Uri;
import android.os.Binder;
import android.os.IBinder;
import android.os.RemoteException;
import android.provider.BaseColumns;
import android.provider.CallLog;
import android.provider.ContactsContract;
import android.support.v4.app.NotificationCompat;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.content.ComponentName;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.lang.Runnable;
import java.lang.reflect.Method;
import java.net.URLEncoder;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

public class Native extends org.qtproject.qt5.android.bindings.QtActivity
{
    private static NotificationManager m_notificationManager;
    private static Notification.Builder m_builder;
    private static Native m_instance = null;

    private static boolean m_guiReady = false;
    private static final String TAG = "Phonehook";
    public static boolean isNativeReady = false;

    private Intent m_launchIntent;

    static ServiceConnection mConnection;
    PhonehookDaemonInterface pdRemote;

    public Native()
    {
        Log.d(TAG, "Initializing activity");
        m_instance = this;
    }
    public static Native instance() {
        if(m_instance == null) {
            return new Native();
        }
        return m_instance;
    }

    public static void setDaemonRunning(final boolean daemonRunning)
    {
        instance().runOnUiThread(new Runnable() {
            public void run() {

                if(daemonRunning) {

                    ComponentName result =
                            instance().startService(new Intent(instance(), MyService.class));

                    if (result == null) {
                        Log.d(TAG, "service not started.");
                    } else {
                        //Log.d(TAG, "phonehook daemon running");
                    }

                    bindService();

                } else {
                    instance().stopService(new Intent(instance(), MyService.class));
                }

            }
        });

    }

    public static String getOperatorCountry() {
        final TelephonyManager telephonyManager = (TelephonyManager) instance().getSystemService(Context.TELEPHONY_SERVICE);
        String iso = telephonyManager.getNetworkCountryIso();
        return iso;
    }

    public static void nativeGuiReady() {
        m_guiReady = true;
        if(isServiceRunning())
            bindService();


        instance().m_launchIntent = instance().getIntent();
        if(instance().m_launchIntent.getExtras() != null) {

            if(instance().m_launchIntent.getExtras().getBoolean("clear", false) == true ) {
                int id = instance().m_launchIntent.getExtras().getInt("id", -1);
                MyService.gotClearIntent(id);
            } else {
                String target = instance().m_launchIntent.getExtras().getString("target", "");
                MyService.gotIntent(target);
            }
        }

    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        m_launchIntent = intent;

        if(m_guiReady) {

            if(intent.getExtras().getBoolean("clear", false) == true ) {
                int id = intent.getExtras().getInt("id", -1);
                MyService.gotClearIntent(id);
            } else {
                String target = intent.getExtras().getString("target", "");
                MyService.gotIntent(target);
            }
        }

    }

    @Override
    protected void onResume() {
        super.onResume();

        if(m_guiReady && isServiceRunning())
            bindService();
    }

    @Override
    protected void onPause() {
        super.onPause();

        if(mConnection != null) {
            unbindService(mConnection);
            instance().pdRemote = null;
            mConnection = null;
        }

    }

    private static void bindService() {
         mConnection = new ServiceConnection() {
            // Called when the connection with the service is established
            public void onServiceConnected(ComponentName className, IBinder service) {
                // Following the example above for an AIDL interface,
                // this gets an instance of the IRemoteInterface, which we can use to call on the service
                instance().pdRemote = PhonehookDaemonInterface.Stub.asInterface(service);
                try {
                    boolean response = instance().pdRemote.ping();
                    MyService.onDaemonStatusChange(response);
                } catch(RemoteException ex) {
                    instance().pdRemote = null;
                    MyService.onDaemonStatusChange(false);
                }
            }

            // Called when the connection with the service disconnects unexpectedly
            public void onServiceDisconnected(ComponentName className) {
                Log.e(TAG, "Service has unexpectedly disconnected");
                instance().pdRemote = null;
                MyService.onDaemonStatusChange(false);
            }
        };

        Intent intent = new Intent(instance(), MyService.class);
        intent.setAction(MyService.class.getName());
        instance().bindService(intent, mConnection, 0);
    }


    public static void nativeReady() {

        Log.d(TAG, "nativeReady");

        isNativeReady = true;

        if(MyService.instance() != null) {
            instance().runOnUiThread(new Runnable() {
                public void run() {
                    MyService.instance().initialize();
                }
            });
        }
    }

    public static boolean sendCommand(final String cmd, final String data) {

        instance().runOnUiThread(new Runnable() {
            public void run() {
                if (HUDView.instance() == null) {
                    Log.d(TAG, "no instance!");
                }

                HUDView.instance().onCommand(cmd, data);
            }
        });

        return true;
    }


    public static String getContactName(String phoneNumber) {
        Log.d(TAG, "getting contact " + phoneNumber);

        ContentResolver cr = MyService.instance().getContentResolver();
        Uri uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber));

        Cursor cursor = cr.query(uri, new String[]{
                        ContactsContract.PhoneLookup.LOOKUP_KEY, ContactsContract.PhoneLookup.DISPLAY_NAME},
                null, null, null);


        if (cursor == null) {
            return null;
        }
        String contactName = null;
        if(cursor.moveToFirst()) {
            contactName = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME));
        }

        if(cursor != null && !cursor.isClosed()) {
            cursor.close();
        }

        return contactName;
    }

    public static String contactIdFromNumber(String phoneNumber) {
        Log.d(TAG, "getting contact id " + phoneNumber);

        ContentResolver cr = MyService.instance().getContentResolver();
        Uri uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber));


        Cursor cursor = cr.query(uri, new String[]{
                        ContactsContract.PhoneLookup.LOOKUP_KEY, ContactsContract.PhoneLookup.DISPLAY_NAME},
                null, null, null);


        if (cursor == null) {
            return "";
        }
        String contactId = "";
        if(cursor.moveToFirst()) {
            contactId = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.LOOKUP_KEY));
        }

        if(cursor != null && !cursor.isClosed()) {
            cursor.close();
        }

        return contactId;
    }


    // called by GUI
    public static String getCallLog(String filter, int offset) {
        ContentResolver cr = instance().getContentResolver();

        JSONArray results = new JSONArray();

        String selection = "";

        if(filter.equals("missed")) {
            selection = CallLog.Calls.TYPE + "=" + CallLog.Calls.MISSED_TYPE;
        } else if(filter.equals("incoming")) {
            selection = CallLog.Calls.TYPE + "=" + CallLog.Calls.INCOMING_TYPE;
        } else if(filter.equals("outgoing")) {
            selection = CallLog.Calls.TYPE + "=" + CallLog.Calls.OUTGOING_TYPE;
        }

        Uri uri =
        CallLog.Calls.CONTENT_URI; //.buildUpon()
                //.appendQueryParameter("LIMIT", "5")
                //.appendQueryParameter("OFFSET", Integer.toString(offset)).build();

        Cursor cursor = cr.query(uri ,
                null, selection, null, "date DESC LIMIT 5 OFFSET "  + Integer.toString(offset) ); //last record first
        while (cursor.moveToNext()) {

            JSONObject result = new JSONObject();

            try {
                Date callDate = new Date(cursor.getLong(cursor.getColumnIndex(CallLog.Calls.DATE)));
                TimeZone tz = TimeZone.getTimeZone("UTC");
                DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mmZ");
                df.setTimeZone(tz);

                result.put("date", df.format(callDate));

                String nr = cursor.getString(cursor.getColumnIndex(CallLog.Calls.NUMBER));
                int presentation = cursor.getInt(cursor.getColumnIndex(CallLog.Calls.NUMBER_PRESENTATION));
                String name = cursor.getString(cursor.getColumnIndex(CallLog.Calls.CACHED_NAME));

                if(presentation == CallLog.Calls.PRESENTATION_UNKNOWN || presentation == CallLog.Calls.PRESENTATION_RESTRICTED) {
                    nr = "";
                    name = "Unknown";
                }

                result.put("number", nr);
                result.put("name", name);

                results.put(result);
            } catch (JSONException e) {
                e.printStackTrace();
            }

            //dialed=c.getLong(c.getColumnIndex(CallLog.Calls.DATE));
            Log.i("CallLog", "type: ");

        }

        return results.toString();

    }

    // called by GUI
    public static String getContactNameById(String contactId) {
        ContentResolver cr = instance().getContentResolver();
        /*Cursor cursor = cr.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                null,
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = ?",
                new String[]{Integer.toString(contactId)}, null);
*/
        Uri lookupUri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_LOOKUP_URI, contactId);
        Uri contactUri = ContactsContract.Contacts.lookupContact(cr, lookupUri);


        if(contactUri == null)
            return "??";

        Cursor cursor = cr.query(contactUri, null, null, null, null);

        while (cursor.moveToNext())
        {
            return cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME));
        }

        return "??";
    };

    public static String getContacts() {
        ContentResolver cr = instance().getContentResolver();
        JSONArray contacts = new JSONArray();

        Cursor cursor = null;

        try {
            cursor = cr.query(ContactsContract.Contacts.CONTENT_URI,
                    null,
                    ContactsContract.PhoneLookup.HAS_PHONE_NUMBER + "=1",
                    null,
                    null);
        } catch (Exception e) {
            e.printStackTrace();
        }


        if (cursor == null || cursor.getCount() == 0) {
            return contacts.toString();
        }

        while(cursor.moveToNext()) {
            JSONObject contact = new JSONObject();
            try {
                contact.put("id", cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.LOOKUP_KEY)));
                contact.put("name", cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)));
                contact.put("picture", cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI)));

                contacts.put(contact);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if(cursor != null && !cursor.isClosed()) {
            cursor.close();
        }

        return contacts.toString();
    }

    public static void startLogin(final int botId, final String loginData) {

        Log.d(TAG, "login start" + loginData);

        Intent intent = new Intent(instance(), Login.class);
        intent.putExtra("com.omnight.phonehook.botId",  botId);
        intent.putExtra("com.omnight.phonehook.loginData", loginData);

        instance().startActivity(intent);

    }

    public static void launchMaps(String address) {
        try {
            String uri = null;
            uri = "geo:0,0?q=" + URLEncoder.encode(address, "utf-8");
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(uri));
            instance().startActivity(intent);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }


    public static Context getContext() {
        Context ctx;
        if(instance().getApplication() != null)
            ctx = instance();
        else
            ctx = MyService.instance();

        return ctx;
    }

    public static void launchAddContact(String name, String address, String number, String url) {




        Intent intent = new Intent(Intent.ACTION_INSERT);
        intent.setType(ContactsContract.Contacts.CONTENT_TYPE);

        intent.putExtra(ContactsContract.Intents.Insert.NAME, name);
        intent.putExtra(ContactsContract.Intents.Insert.POSTAL, address);

        ArrayList<ContentValues> data = new ArrayList<ContentValues>();

        String numbers[] = number.split("\\|");
        for (int i = 0; i < numbers.length; i++) {
            String nr = numbers[i];
            if(nr.length() == 0) continue;

            ContentValues row = new ContentValues();
            row.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE);
            row.put(ContactsContract.CommonDataKinds.Phone.NUMBER, nr);
             data.add(row);
        }

        if(!url.isEmpty()) {
            ContentValues row1 = new ContentValues();
            row1.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE);
            row1.put(ContactsContract.CommonDataKinds.Website.URL, url);
            //row1.put(ContactsContract.CommonDataKinds.Website.LABEL, "Phonehook");
            row1.put(ContactsContract.CommonDataKinds.Website.TYPE, ContactsContract.CommonDataKinds.Website.TYPE_HOME);
            data.add(row1);
        }

        if(!data.isEmpty())
            intent.putParcelableArrayListExtra(ContactsContract.Intents.Insert.DATA, data);

        if(getContext() == MyService.instance())
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        getContext().startActivity(intent);
    }

    public static void launchNumber(String number) {
        Intent intent = new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + number));
        instance().startActivity(intent);
    }

    public static boolean testNumber(int botId, String number) {
        try {
            if(instance().pdRemote == null) return false;
            instance().pdRemote.testLookup(botId, number);
            return true;
        } catch (RemoteException e) {
            return false;
        }
    }

    public static boolean isServiceRunning() {

        ActivityManager manager = (ActivityManager)instance().getSystemService(Context.ACTIVITY_SERVICE);
        for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (MyService.class.getName().equals(service.service.getClassName()) && service.started) {
                return true;
            }
        }
        return false;
    }


    public static void disconnectCall(){
        try {

            String serviceManagerName = "android.os.ServiceManager";
            String serviceManagerNativeName = "android.os.ServiceManagerNative";
            String telephonyName = "com.android.internal.telephony.ITelephony";
            Class<?> telephonyClass;
            Class<?> telephonyStubClass;
            Class<?> serviceManagerClass;
            Class<?> serviceManagerNativeClass;
            Method telephonyEndCall;
            Object telephonyObject;
            Object serviceManagerObject;
            telephonyClass = Class.forName(telephonyName);
            telephonyStubClass = telephonyClass.getClasses()[0];
            serviceManagerClass = Class.forName(serviceManagerName);
            serviceManagerNativeClass = Class.forName(serviceManagerNativeName);
            Method getService = // getDefaults[29];
                    serviceManagerClass.getMethod("getService", String.class);
            Method tempInterfaceMethod = serviceManagerNativeClass.getMethod("asInterface", IBinder.class);
            Binder tmpBinder = new Binder();
            tmpBinder.attachInterface(null, "fake");
            serviceManagerObject = tempInterfaceMethod.invoke(null, tmpBinder);
            IBinder retbinder = (IBinder) getService.invoke(serviceManagerObject, "phone");
            Method serviceMethod = telephonyStubClass.getMethod("asInterface", IBinder.class);
            telephonyObject = serviceMethod.invoke(null, retbinder);
            telephonyEndCall = telephonyClass.getMethod("endCall");
            telephonyEndCall.invoke(telephonyObject);

        } catch (Exception e) {
            e.printStackTrace();
            //Log.error(DialerActivity.this,
//                    "FATAL ERROR: could not connect to telephony subsystem");
//            Log.error(DialerActivity.this, "Exception object: " + e);
        }
    }

    public static void createNotification(int id, String title, String text, String bigText, String target) {
        NotificationCompat.Builder mBuilder =
                new NotificationCompat.Builder(getContext())
                        .setSmallIcon(R.drawable.notificon)
                        .setContentTitle(title)
                        .setContentText(text);

        if(!bigText.equals("")) {
            mBuilder.setStyle(new NotificationCompat.BigTextStyle().bigText(bigText));
        }


// Creates an explicit intent for an Activity in your app

        Intent resultIntent = new Intent(getContext(), Native.class);
        resultIntent.putExtra("target", target);

        PendingIntent callback = PendingIntent.getActivity(
                getContext(),
                0,
                resultIntent,
                PendingIntent.FLAG_UPDATE_CURRENT);

        Intent clearIntent = new Intent(getContext(), MyService.class);
        clearIntent.putExtra("id", id);
        clearIntent.putExtra("clear", true);

        PendingIntent clearBack = PendingIntent.getService(
                getContext(),
                0,
                clearIntent,
                PendingIntent.FLAG_UPDATE_CURRENT
        );

        mBuilder.setAutoCancel(true);
        mBuilder.setContentIntent(callback);
        mBuilder.setDeleteIntent(clearBack);

        NotificationManager mNotificationManager =
                (NotificationManager) getContext().getSystemService(Context.NOTIFICATION_SERVICE);
// mId allows you to update the notification later on.
        mNotificationManager.notify(id, mBuilder.build());


    }
}

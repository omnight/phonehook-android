package com.omnight.phonehook;

import android.app.ActionBar;
import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.IBinder;
import android.os.RemoteException;
import android.telephony.ServiceState;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.Toast;
import android.util.Log;
import android.content.Context;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;

import org.qtproject.qt5.android.addons.qtserviceapp.QtService;


public class MyService extends QtService {

    private static final String TAG = "Phonehook";

    private static native void incomingCall(String nr);
    private static native void testNumber(int botId, String nr);
    private static native void setNetwork(int mcc, int mnc);


    // these actually belong to GUI and not service
    public static native void postLogin(int botId, String success_tag, String loginUrl, String loginHttp);
    public static native void loginCancel();
    public static native void onDaemonStatusChange(boolean status);
    public static native void blockLastCaller();
    public static native void saveLastCaller();
    public static native void gotIntent(String target);
    public static native void gotClearIntent(int id);

    public static native String translate(String text);

    private static MyService instance = null;

    HUDView mView;
    private boolean m_hasInitialized = false;
    private Intent startIntent = null;


    private final PhonehookDaemonInterface.Stub pdi = new PhonehookDaemonInterface.Stub() {
        @Override
        public void testLookup(int botId, String nr) throws RemoteException {
            testNumber(botId, nr);
        }

        @Override
        public boolean ping() {
/*
            if(!instance().started) {
                instance().stopSelf();
                System.exit(0);
                return false;
            }*/

            return true;
        }


        @Override
        public IBinder asBinder() {
            return null;
        }
    };

   @Override
   public IBinder onBind(Intent arg0) {
      return pdi;
   }

    @Override
    public void onCreate() {
        super.setActivityClass(Native.class);
        super.onCreate();
        instance = this;

        mView = new HUDView(this);
        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL |
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,  //                 WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH |
                PixelFormat.TRANSLUCENT);
        params.gravity = Gravity.CENTER_VERTICAL;

        //params.horizontalMargin = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 30, getResources().getDisplayMetrics());
        params.setTitle("phonehook");
        WindowManager wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        wm.addView(mView, params);

        Native.instance();

        Log.d(TAG, "service onCreate");

    }

    public static MyService instance() {
        if(instance != null)
            return instance;
        return null;
    }

    public void initialize() {
        final TelephonyManager telephonyManager = (TelephonyManager) getSystemService(Context.TELEPHONY_SERVICE);
        final MyService self = this;

        // get initial value
        String networkOperator = telephonyManager.getNetworkOperator();

        Log.d(TAG, "Network Operator: " + networkOperator);

        if (networkOperator != null && networkOperator.length() > 3) {
            int mcc = Integer.parseInt(networkOperator.substring(0, 3));
            int mnc = Integer.parseInt(networkOperator.substring(3));

            setNetwork(mcc, mnc);
        }

        PhoneStateListener phoneStateListener = new PhoneStateListener() {
            @Override
            public void onCallStateChanged(int state, String number) {
                String currentPhoneState = null;
                Log.d(TAG, "PhoneState " + number + " __ " + state);
                switch (state) {
                    case TelephonyManager.CALL_STATE_RINGING:
                        //currentPhoneState = "Device is ringing. Call from " + number + ".\n\n";
                        incomingCall(number);
                        break;
                    case TelephonyManager.CALL_STATE_OFFHOOK:
                        //currentPhoneState = "Device call state is currently Off Hook.\n\n";
                        break;
                    case TelephonyManager.CALL_STATE_IDLE:
                        //currentPhoneState = "Device call state is currently Idle.\n\n";
                        break;
                }
                //Toast.makeText(self, currentPhoneState, Toast.LENGTH_LONG).show();

            }

            @Override
            public void onServiceStateChanged(ServiceState serviceState) {
                if(serviceState.equals(ServiceState.STATE_IN_SERVICE)) {
                    String networkOperator = telephonyManager.getNetworkOperator();

                    Log.d(TAG, "Network Operator: " + networkOperator);

                    if (networkOperator != null && networkOperator.length() > 3) {
                        int mcc = Integer.parseInt(networkOperator.substring(0, 3));
                        int mnc = Integer.parseInt(networkOperator.substring(3));

                        setNetwork(mcc, mnc);
                    }
                }
            }
        };
        telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE | PhoneStateListener.LISTEN_SERVICE_STATE);

        m_hasInitialized = true;

        if(startIntent != null) {
            gotClearIntent(startIntent.getIntExtra("id", -1));
            startIntent = null;
        }
    }



    @Override
   public int onStartCommand(Intent intent, int flags, int startId) {
        super.onStartCommand(intent,flags,startId);

      // Let it continue running until it is stopped.
      //Toast.makeText(this, "Service Started", Toast.LENGTH_LONG).show();

      if(intent != null)
        Log.d(TAG, "Service Start Command = " + intent.toString());

      if(Native.isNativeReady && !m_hasInitialized) {
          initialize();
          Log.d(TAG, "phonehook daemon running");
      }

      // when user clears notification
      if(intent != null && intent.getBooleanExtra("clear", false) == true && intent.hasExtra("id")) {
          if(Native.isNativeReady) {
              gotClearIntent(intent.getIntExtra("id", -1));
          } else {
              startIntent = intent;
          }
      }

      return START_STICKY;
   }

   @Override
   public void onDestroy() {
      super.onDestroy();
      Toast.makeText(this, "Service Destroyed", Toast.LENGTH_LONG).show();
   }
}

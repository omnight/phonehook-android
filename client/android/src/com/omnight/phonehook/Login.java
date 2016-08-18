package com.omnight.phonehook;

import 	android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.CookieManager;
import java.net.CookiePolicy;

public class Login extends Activity {

    protected JSONObject loginData;
    protected int botId;
    protected Login thisLoginActivity;
    protected String success_url;

    class HtmlExtractInterface {

        private Context ctx;

        HtmlExtractInterface(Context ctx) {
            this.ctx = ctx;
        }

        public void result(String html) {

           // new AlertDialog.Builder(ctx).setTitle("HTML").setMessage(html)
//                    .setPositiveButton(android.R.string.ok, null).setCancelable(false).create().show();

            try {
                MyService.postLogin(botId, loginData.getString("login_success_tag"), success_url, html );
            } catch (JSONException e) {
                e.printStackTrace();
            }
            thisLoginActivity.finish();

        }

    }

    private class Callback extends WebViewClient {  //HERE IS THE MAIN CHANGE.


        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);

            try {
                if(url.startsWith(loginData.getString("login_success_url"))) {
                    android.webkit.CookieManager.getInstance().flush();
                    success_url = url;
                    view.loadUrl("javascript:window.Phonehook.result" +
                            "(document.documentElement.outerHTML);");
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }

        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            return false;
        }

    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        thisLoginActivity = this;

        android.webkit.CookieManager.getInstance();
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.activity_login);

        Intent intent = getIntent();

        android.webkit.CookieManager.getInstance().removeAllCookie();

        botId = intent.getIntExtra("com.omnight.phonehook.botId", 0);
        String loginDataString = intent.getStringExtra("com.omnight.phonehook.loginData");

        try {
            loginData = new JSONObject(loginDataString);

            ((TextView)findViewById(R.id.loginTitle)).setText(loginData.getString("name"));

            WebView wv = (WebView)findViewById(R.id.loginView);

            wv.addJavascriptInterface(new HtmlExtractInterface(this), "Phonehook");

            WebSettings webSettings = wv.getSettings();
            webSettings.setJavaScriptEnabled(true);

            wv.setWebViewClient(new Callback());
            wv.loadUrl(loginData.getString("url"));

        } catch (JSONException e) {
            e.printStackTrace();
        }



        ((Button) findViewById(R.id.loginDebug)).setOnClickListener(new View.OnClickListener() {
                                                                        @Override
                                                                        public void onClick(View view) {
                                                                            MyService.loginCancel();
                                                                            thisLoginActivity.finish();
                                                                            //MyService.syncCookies(botId);
                                                                            //Log.d("COOKIES", Integer.toString(android.webkit.CookieManager.getInstance().getCookie()   );
                                                                        }
                                                                    }
        );

    }
}

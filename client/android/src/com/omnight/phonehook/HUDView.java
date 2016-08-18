package com.omnight.phonehook;

import android.animation.Animator;
import android.animation.TimeInterpolator;
import android.content.Context;
import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.net.Uri;
import android.support.v4.view.MotionEventCompat;
import android.text.Html;
import android.util.TypedValue;
import android.view.DragEvent;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.TouchDelegate;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.BounceInterpolator;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import android.util.Log;
import android.widget.ViewFlipper;


import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.List;
import java.util.ArrayList;


/**
 * Created by xjohekm on 2015-12-03.
 */
class HUDView extends LinearLayout {
    //private Paint mLoadPaint;
    private static HUDView instance = null;
    private static final String TAG = "Phonehook";


    private String field_address;

    private List<JSONObject> allResults = new ArrayList<JSONObject>();

    public static HUDView instance() {
        if(instance != null)
            return instance;
        return null;
    }


    public boolean onCommand(String cmd, String data) {

        Log.d(TAG, cmd + " -- " + data);

        try {
            switch (cmd) {
                case "lookupResult":

                    //for(int xx=0; xx < 10; xx++) {

                        JSONArray result = new JSONArray(data);
                        for (int i = 0; i < result.length(); i++) {

                            //if(arr[i].tagname=='block')
                            //adWarning = true;

                            if (result.getJSONObject(i).getString("tagname").equals("field") && result.getJSONObject(i).has("value")) {
                                LayoutParams lp = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
                                View v = LayoutInflater.from(getContext()).inflate(R.layout.result_item, null);

                                if (result.getJSONObject(i).has("stitle")) {
                                    ((TextView) v.findViewById(R.id.resultItemHeader)).setText( MyService.translate( result.getJSONObject(i).getString("stitle") ));

                                    if(result.getJSONObject(i).getString("stitle").equals("address") && field_address.equals("")) {
                                        field_address = result.getJSONObject(i).getString("value");
                                        getRootView().findViewById(R.id.containerButtonNavigate).setVisibility(VISIBLE);
                                    }

                                }

                                String unHtml = Html.fromHtml(result.getJSONObject(i).getString("value")).toString();
                                ((TextView) v.findViewById(R.id.resultItemBody)).setText(unHtml);

                                if (result.getJSONObject(i).has("source"))
                                    ((TextView) v.findViewById(R.id.resultItemSource)).setText(" - " + result.getJSONObject(i).getString("source"));

                                ((LinearLayout) findViewById(R.id.resultData)).addView(v, lp);
                            } else if (result.getJSONObject(i).getString("tagname").equals("block")) {
                                getRootView().findViewById(R.id.alertWarning).setVisibility(VISIBLE);
                            }
                        }
                    //}
                    break;

                case "setPosition":
                    WindowManager.LayoutParams lp = (WindowManager.LayoutParams) instance().getLayoutParams();

                    int newGravity=0;

                    if(data.equals("0"))
                        newGravity = Gravity.TOP;
                    if(data.equals("1"))
                        newGravity = Gravity.CENTER;
                    if(data.equals("2"))
                        newGravity = Gravity.BOTTOM;

                    if(newGravity == lp.gravity) break;

                    lp.gravity = newGravity;

                    //instance().setLayoutParams(lp);
                    //instance().invalidate();

                    WindowManager wm = (WindowManager) MyService.instance().getSystemService(MyService.instance().WINDOW_SERVICE);
                    wm.removeView(instance());
                    wm.addView(instance(), lp);

                    break;


                case "stateChange":

                    if(data.equals("activate:lookup")) {
                        animateOpen();
                        findViewById(R.id.statusBar).setVisibility(VISIBLE);
                        View no_results = findViewById(R.id.noResultsInfo);
                        LinearLayout result_list = ((LinearLayout)findViewById(R.id.resultData));
                        while(result_list.getChildCount() > 1)
                            result_list.removeViewAt(1);

                        findViewById(R.id.alertWarning).setVisibility(GONE);
                        no_results.setVisibility(GONE);
                        field_address = "";
                        findViewById(R.id.containerButtonNavigate).setVisibility(GONE);
                    } else if(data.equals("finished")) {

                        if(((LinearLayout)findViewById(R.id.resultData)).getChildCount() <= 1) {
                            findViewById(R.id.noResultsInfo).setVisibility(VISIBLE);
                        }

                        findViewById(R.id.statusBar).setVisibility(GONE);
                    } else if(data.indexOf("running:") == 0 ) {
                        ((TextView)findViewById(R.id.statusText)).setText(data.replace("running:", ""));
                    }

                    break;

            }

            postInvalidate();

            return true;

        } catch (JSONException e) {
            e.printStackTrace();
            return false;
        }
    }

    private View innerWindow;

    public void animateOpen() {
        innerWindow.setAlpha(0);
        ((ViewFlipper) findViewById(R.id.viewFlipper)).setDisplayedChild(0);
        ((ImageButton)findViewById(R.id.btnMenu)).clearColorFilter();
        innerWindow.setScaleY(0f);

        HUDView.instance().setVisibility(VISIBLE);

        innerWindow.animate()
                .scaleY(1)
                .alpha(1)
                .setDuration(500)
                .setInterpolator(new BounceInterpolator())
                .setListener(null);

    }


    public void animateClose() {

        innerWindow.animate()
                .scaleY(0)
                .alpha(0)
                .setDuration(500)
                .setInterpolator(null)
                .setListener(new Animator.AnimatorListener() {
                    @Override
                    public void onAnimationStart(Animator animator) {

                    }

                    @Override
                    public void onAnimationEnd(Animator animator) {
                        HUDView.instance().setVisibility(GONE);
                    }

                    @Override
                    public void onAnimationCancel(Animator animator) {

                    }

                    @Override
                    public void onAnimationRepeat(Animator animator) {

                    }
                });


    }

    public void close() {
        innerWindow.setX(0);
        innerWindow.setAlpha(1);
        HUDView.instance().setVisibility(GONE);
    }

    public HUDView(Context context) {
        super(context);
        instance = this;

        LayoutParams lp = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        innerWindow = LayoutInflater.from(this.getContext()).inflate(R.layout.popup_layout, null);
        this.addView(innerWindow, lp);

        ((ImageButton)findViewById(R.id.btnClose)).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                instance().animateClose();
            }
        });


        ((StuntScrollView)findViewById(R.id.scrollView)).setTouchEventListener(new StuntScrollView.touchE() {
            @Override
            public void touchEvent(MotionEvent ev) {
                instance().onTouchEvent(ev);
            }
        });

        ((ImageButton)findViewById(R.id.btnMenu)).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                ViewFlipper vf = ((ViewFlipper) findViewById(R.id.viewFlipper));
                vf.showNext();

                if (vf.getDisplayedChild() == 1)
                    ((ImageButton) findViewById(R.id.btnMenu)).setColorFilter(Color.GREEN);
                else
                    ((ImageButton) findViewById(R.id.btnMenu)).clearColorFilter();
            }
        });

        ((ImageButton)findViewById(R.id.buttonNavigate)).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                try {
                    String uri = null;
                    uri = "geo:0,0?q=" + URLEncoder.encode(field_address, "utf-8");
                    Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(uri));
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    MyService.instance().startActivity(intent);
                    animateClose();
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
            }
        });

        ((ImageButton)findViewById(R.id.buttonBlock)).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                MyService.blockLastCaller();
                animateClose();
            }
        });

        ((ImageButton)findViewById(R.id.buttonSave)).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                MyService.saveLastCaller();
                animateClose();
            }
        });

        this.setVisibility(GONE);
    }

    float dragStart;
    float dragOffset;
    float dragSpeed;

    WindowManager wm = (WindowManager) MyService.instance().getSystemService(MyService.WINDOW_SERVICE);

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return onInterceptTouchEvent(event);
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {

        switch (event.getActionMasked()) {

            case MotionEvent.ACTION_DOWN:
                dragStart = event.getRawX();
                dragSpeed = 0;
                break;

            case MotionEvent.ACTION_UP:
                //((StuntScrollView)findViewById(R.id.scrollView)).scrollLock = false;

                if (Math.abs(dragOffset) > innerWindow.getWidth() / 3 || Math.abs(dragSpeed) > innerWindow.getWidth() / 10) {
                    innerWindow.animate()
                            .x(dragOffset / Math.abs(dragOffset) * innerWindow.getWidth())
                            .alpha(0)
                            .setDuration(500)
                            .setInterpolator(null)
                            .setListener(new Animator.AnimatorListener() {
                                @Override
                                public void onAnimationStart(Animator animator) {

                                }

                                @Override
                                public void onAnimationEnd(Animator animator) {
                                    instance().close();
                                }

                                @Override
                                public void onAnimationCancel(Animator animator) {

                                }

                                @Override
                                public void onAnimationRepeat(Animator animator) {

                                }
                            });

                } else {
                    dragOffset = 0;
                    innerWindow.animate().cancel();
                    innerWindow.animate()
                            .x(dragOffset)
                            .alpha(1)
                            .setDuration(500)
                            .setInterpolator(new BounceInterpolator())
                            .setListener(null);
                }


                break;

            case MotionEvent.ACTION_MOVE:


                float oldDragOffset = dragOffset;
                dragOffset = event.getRawX() - dragStart;


                //if(dragOffset > innerWindow.getWidth() / 20 )
                //    ((StuntScrollView)findViewById(R.id.scrollView)).scrollLock = true;

                dragSpeed = dragOffset - oldDragOffset;
                innerWindow.setX(dragOffset);
                innerWindow.setAlpha(1 - Math.min(1, Math.abs(dragOffset * 2) / innerWindow.getWidth()));

                break;
            default:
                return false;
        }

        return false;
    }

}

package com.omnight.phonehook;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ScrollView;

/**
 * Created by xjohekm on 2016-01-19.
 */
public class StuntScrollView extends ScrollView {

    public interface  touchE {
        public void touchEvent(MotionEvent ev);
    }

    public StuntScrollView(Context context) {
        super(context);
    }

    public StuntScrollView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public StuntScrollView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    private touchE listener = null;

    public void setTouchEventListener(touchE e) {
        listener = e;
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        heightMeasureSpec = MeasureSpec.makeMeasureSpec(300, MeasureSpec.AT_MOST);
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }

    @Override
    public boolean onTouchEvent(MotionEvent ev) {
        if(listener != null) listener.touchEvent(ev);
        return super.onTouchEvent(ev);
    }
}

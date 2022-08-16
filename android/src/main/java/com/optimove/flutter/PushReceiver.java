package com.optimove.flutter;

import android.app.Activity;
import android.app.TaskStackBuilder;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import com.optimove.android.Optimove;
import com.optimove.android.optimobile.Optimobile;
import com.optimove.android.optimobile.PushBroadcastReceiver;
import com.optimove.android.optimobile.PushMessage;
import org.json.JSONException;
import java.util.HashMap;
import java.util.Map;

public class PushReceiver extends PushBroadcastReceiver {

    static Map<String, Object> pushMessageToMap(PushMessage pushMessage, String actionId) {
        Map<String, Object> message = new HashMap<>(6);

        try {
            message.put("id", pushMessage.getId());
            message.put("title", pushMessage.getTitle());
            message.put("message", pushMessage.getMessage());
            message.put("actionId", actionId);
            message.put("data", JsonUtils.toMap(pushMessage.getData()));

            if (null != pushMessage.getUrl()) {
                message.put("url", pushMessage.getUrl().toString());
            } else {
                message.put("url", null);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return message;
    }

    @Override
    protected void onPushReceived(Context context, PushMessage pushMessage) {
        super.onPushReceived(context, pushMessage);

        Map<String, Object> event = new HashMap<>(2);
        event.put("type", "push.received");
        event.put("data", pushMessageToMap(pushMessage, null));
        OptimoveFlutterPlugin.eventSink.send(event, false);
    }

    @Override
    protected void onPushOpened(Context context, PushMessage pushMessage) {
        try {
            Optimove.getInstance().pushTrackOpen(pushMessage.getId());
        } catch (Optimobile.UninitializedException ignored) {
        }

        PushReceiver.handlePushOpen(context, pushMessage, null);
    }

    @SuppressWarnings("unchecked")
    public static void handlePushOpen(Context context, PushMessage pushMessage, String actionId) {
        PushReceiver pr = new PushReceiver();
        Intent launchIntent = pr.getPushOpenActivityIntent(context, pushMessage);

        if (null == launchIntent) {
            return;
        }

        ComponentName component = launchIntent.getComponent();
        if (null == component) {
            return;
        }

        Class<? extends Activity> cls = null;
        try {
            cls = (Class<? extends Activity>) Class.forName(component.getClassName());
        } catch (ClassNotFoundException e) {
            /* Noop */
        }

        // Ensure we're trying to launch an Activity
        if (null == cls) {
            return;
        }

        Activity currentActivity = OptimoveFlutterPlugin.currentActivityRef.get();
        if (null != currentActivity) {
            Intent existingIntent = currentActivity.getIntent();
            addDeepLinkExtras(pushMessage, existingIntent);
        }

        if (null != pushMessage.getUrl()) {
            launchIntent = new Intent(Intent.ACTION_VIEW, pushMessage.getUrl());

            addDeepLinkExtras(pushMessage, launchIntent);

            TaskStackBuilder taskStackBuilder = TaskStackBuilder.create(context);
            taskStackBuilder.addParentStack(component);
            taskStackBuilder.addNextIntent(launchIntent);
            taskStackBuilder.startActivities();
        } else {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);

            addDeepLinkExtras(pushMessage, launchIntent);

            context.startActivity(launchIntent);
        }

        Map<String, Object> event = new HashMap<>(2);
        event.put("type", "push.opened");
        event.put("data", pushMessageToMap(pushMessage, actionId));
        OptimoveFlutterPlugin.eventSinkDelayed.send(event);
    }
}
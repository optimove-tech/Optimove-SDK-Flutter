package com.optimove.flutter.events;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.optimove.android.optimobile.PushMessage;
import com.optimove.flutter.JsonUtils;

import org.json.JSONException;

import java.util.HashMap;
import java.util.Map;

public abstract class PushEvent {
    @NonNull
    private final PushMessage pushMessage;

    protected PushEvent(@NonNull PushMessage pushMessage) {
        this.pushMessage = pushMessage;
    }

    protected Map<String, Object> pushMessageToMap(@Nullable String actionId) {
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

}

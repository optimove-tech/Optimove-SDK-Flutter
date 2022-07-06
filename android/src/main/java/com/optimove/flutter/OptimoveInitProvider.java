package com.optimove.flutter;

import android.app.Application;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.res.AssetManager;
import android.database.Cursor;
import android.net.Uri;
import android.util.JsonReader;
import android.util.JsonToken;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.optimove.android.Optimove;
import com.optimove.android.OptimoveConfig;
import com.optimove.android.optimobile.DeferredDeepLinkHandlerInterface;

import org.json.JSONException;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.jar.Attributes;
import java.util.HashMap;

import io.flutter.plugin.common.PluginRegistry;

public class OptimoveInitProvider extends ContentProvider {
    private static final String TAG = OptimoveInitProvider.class.getName();
    private static final String OPTIMOVE_CREDENTIALS = "optimoveCredentials";
    private static final String OPTIMOBILE_CREDENTIALS = "optimobileCredentials";
    private static final String KEY_IN_APP_CONSENT_STRATEGY = "inAppConsentStrategy";
    private static final String IN_APP_AUTO_ENROLL = "auto-enroll";
    private static final String IN_APP_EXPLICIT_BY_USER = "explicit-by-user";
    private static final String KEY_ENABLE_DDL = "enableDeferredDeepLinking";

    @Override
    public boolean onCreate() {
        OptimoveConfig.Builder config;
        try {
            config = readConfig();
        } catch (IOException e) {
            e.printStackTrace();
            return true;
        }
        if (config == null) {
            Log.i(TAG, "Skipping init, no config file found...");
            return true;
        }
        Application application = (Application) getContext().getApplicationContext();
        Optimove.initialize(application, config.build());

        return false;
    }

    @Nullable
    @Override
    public Cursor query(@NonNull Uri uri, @Nullable String[] strings, @Nullable String s, @Nullable String[] strings1,
                        @Nullable String s1) {
        return null;
    }

    @Nullable
    @Override
    public String getType(@NonNull Uri uri) {
        return null;
    }

    @Nullable
    @Override
    public Uri insert(@NonNull Uri uri, @Nullable ContentValues contentValues) {
        return null;
    }

    @Override
    public int delete(@NonNull Uri uri, @Nullable String s, @Nullable String[] strings) {
        return 0;
    }

    @Override
    public int update(@NonNull Uri uri, @Nullable ContentValues contentValues, @Nullable String s,
                      @Nullable String[] strings) {
        return 0;
    }

    private JsonReader getConfigReader() {
        String path = "flutter_assets" + File.separator + "optimove.json";
        AssetManager assetManager = getContext().getAssets();
        InputStream is = null;
        try {
            is = assetManager.open(path);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
        JsonReader reader;
        reader = new JsonReader(new InputStreamReader(is, StandardCharsets.UTF_8));

        return reader;
    }

    private OptimoveConfig.Builder readConfig() throws IOException {
        JsonReader reader = getConfigReader();
        if (null == reader) {
            return null;
        }

        String optimoveCredentials = null;
        String optimobileCredentilas = null;
        String inAppConsentStrategy = null;
        boolean enableDeepLinking = false;
        String deepLinkingCname = null;

        try {
            reader.beginObject();
            while (reader.hasNext()) {
                String key = reader.nextName();
                switch (key) {
                    case OPTIMOVE_CREDENTIALS:
                        optimoveCredentials = reader.nextString();
                        break;
                    case OPTIMOBILE_CREDENTIALS:
                        optimobileCredentilas = reader.nextString();
                        break;
                    case KEY_IN_APP_CONSENT_STRATEGY:
                        inAppConsentStrategy = reader.nextString();
                        break;
                    case KEY_ENABLE_DDL:
                        JsonToken tok = reader.peek();
                        if (JsonToken.BOOLEAN == tok) {
                            enableDeepLinking = reader.nextBoolean();
                        } else if (JsonToken.STRING == tok) {
                            enableDeepLinking = true;
                            deepLinkingCname = reader.nextString();
                        } else {
                            reader.skipValue();
                        }
                        break;
                    default:
                        reader.skipValue();
                        break;
                }
            }
            reader.endObject();
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }

        OptimoveConfig.Builder configBuilder = new OptimoveConfig.Builder(optimoveCredentials, optimobileCredentilas);

//        if (inAppConsentStrategy != null) {
//            configureInAppMessaging(configBuilder, inAppConsentStrategy);
//        }
        if (enableDeepLinking) {
            configureDeepLinking(configBuilder, deepLinkingCname);
        }

        return configBuilder;
    }

//    private void configureInAppMessaging(@NonNull OptimoveConfig.Builder config, @NonNull String inAppConsentStrategy) {
//        if (IN_APP_AUTO_ENROLL.equals(inAppConsentStrategy)) {
//            config.enableInAppMessaging(KumulosConfig.InAppConsentStrategy.AUTO_ENROLL);
//        } else if (IN_APP_EXPLICIT_BY_USER.equals(inAppConsentStrategy)) {
//            config.enableInAppMessaging(KumulosConfig.InAppConsentStrategy.EXPLICIT_BY_USER);
//        }
//
//        if (IN_APP_AUTO_ENROLL.equals(inAppConsentStrategy) || IN_APP_EXPLICIT_BY_USER.equals(inAppConsentStrategy)) {
//            KumulosInApp.setDeepLinkHandler((context, data) -> {
//                Map<String, Object> event = new HashMap<>(2);
//                event.put("type", "in-app.deepLinkPressed");
//                try {
//                    event.put("data", JsonUtils.toMap(data));
//                } catch (JSONException e) {
//                    e.printStackTrace();
//                    return;
//                }
//                KumulosSdkFlutterPlugin.eventSink.send(event);
//            });
//            KumulosInApp.setOnInboxUpdated(() -> {
//                EventChannel.EventSink sink = KumulosSdkFlutterPlugin.inAppEventSink;
//
//                if (sink == null) {
//                    return;
//                }
//
//                Map<String, String> event = new HashMap<>(1);
//                event.put("type", "inbox.updated");
//                sink.success(event);
//            });
//        }
//    }

    private void configureDeepLinking(@NonNull OptimoveConfig.Builder config, @Nullable String deepLinkingCname) {
        DeferredDeepLinkHandlerInterface handler = (context, resolution, link, data) -> {
            Map<String, Object> linkMap = null;
            if (null != data) {
                linkMap = new HashMap<>(2);

                Map<String, Object> contentMap = new HashMap<>(2);
                contentMap.put("title", data.content.title);
                contentMap.put("description", data.content.description);

                linkMap.put("content", contentMap);

                try {
                    linkMap.put("data", data.data != null ? JsonUtils.toMap(data.data) : null);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            Map<String, Object> eventData = new HashMap<>(3);
            eventData.put("url", link);
            eventData.put("resolution", resolution.ordinal());
            eventData.put("link", linkMap);

            Map<String, Object> event = new HashMap<>(2);
            event.put("type", "deep-linking.linkResolved");
            event.put("data", eventData);

            OptimoveFlutterSdkPlugin.eventSink.send(event);
        };

        if (deepLinkingCname != null) {
            config.enableDeepLinking(deepLinkingCname, handler);
        } else {
            config.enableDeepLinking(handler);
        }
    }
}

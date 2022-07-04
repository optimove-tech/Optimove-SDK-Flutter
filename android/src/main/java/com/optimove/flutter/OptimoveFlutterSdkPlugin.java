package com.optimove.flutter;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import com.optimove.android.Optimove;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** OptimoveFlutterSdkPlugin */
public class OptimoveFlutterSdkPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private EventChannel eventChannel;
  private Context context;


  static WeakReference<Activity> currentActivityRef = new WeakReference<>(null);
  static QueueingEventStreamHandler eventSink = new QueueingEventStreamHandler();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "optimove_flutter_sdk");
    channel.setMethodCallHandler(this);
    eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "optimove_flutter_sdk_events");
    eventChannel.setStreamHandler(eventSink);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    currentActivityRef = new WeakReference<>(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    currentActivityRef = new WeakReference<>(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    currentActivityRef = new WeakReference<>(null);
  }

  @Override
  public void onDetachedFromActivity() {
    currentActivityRef = new WeakReference<>(null);
  }


  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method){//preparing for alot of different options
      case "registerUser":
        handleRegisterUser(call, result);
        break;
      case "setUserId":
        handleSetUserId(call, result);
        break;
      case "setUserEmail":
        handleSetUserEmail(call, result);
        break;
      case "getVisitorId":
        handleGetVisitorId(result);
        break;
      case "reportEvent":
        handleReportEvent(call, result);
        break;
      case "reportScreenVisit":
        handleReportScreenVisit(call, result);
        break;
      case "getCurrentUserIdentifier":
        handleGetCurrentUserIdentifier(result);
        break;
      default: result.notImplemented();
    }
  }

  private void handleGetCurrentUserIdentifier(Result result) {
    String userIdentifier = Optimove.getInstance().getCurrentUserIdentifier();
    result.success(userIdentifier);
  }

  private void handleReportScreenVisit(MethodCall call, Result result) {
    String screenCategory = call.argument("screenCategory");

    if (screenCategory == null) {
      Optimove.getInstance().reportScreenVisit(call.argument("screenName"));
    } else {
      Optimove.getInstance().reportScreenVisit(call.argument("screenName"), screenCategory);
    }
    result.success(null);
  }

  private void handleReportEvent(MethodCall call, Result result) {
    Map<String, Object> parameters = call.argument("parameters");

    if (parameters == null) {
      String event = call.argument("event");
      Optimove.getInstance().reportEvent(event);
    } else {
      Optimove.getInstance().reportEvent(call.argument("event"), parameters);

    }
    result.success(null);
  }

  private void handleGetVisitorId(Result result) {
    String visitorId = Optimove.getInstance().getVisitorId();
    result.success(visitorId);
  }

  private void handleSetUserEmail(MethodCall call, Result result) {
    Optimove.getInstance().setUserEmail(call.argument("email"));
    result.success(null);
  }

  private void handleSetUserId(MethodCall call, Result result) {
    Optimove.getInstance().setUserId(call.argument("userId"));
    result.success(null);
  }

  private void handleRegisterUser(MethodCall call, Result result) {
    String userId = call.argument("userId");
    String email = call.argument("email");
    Optimove.getInstance().registerUser(userId, email);
    result.success(null);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    channel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
    eventSink.onCancel(null);
    context = null;
  }


  /**
   * package
   */
  static class QueueingEventStreamHandler implements EventChannel.StreamHandler {

    private final ArrayList<Object> eventQueue = new ArrayList<>(1);
    private EventChannel.EventSink eventSink;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink eventSink) {
      synchronized (this) {
        this.eventSink = eventSink;

        for (Object event : eventQueue) {
          this.eventSink.success(event);
        }

        eventQueue.clear();
      }
    }

    @Override
    public void onCancel(Object arguments) {
      synchronized (this) {
        eventSink = null;
        eventQueue.clear();
      }
    }

    public synchronized void send(Object event) {
      send(event, true);
    }

    public synchronized void send(Object event, boolean queueIfNotReady) {
      if (null == eventSink) {
        if (queueIfNotReady) {
          eventQueue.add(event);
        }
        return;
      }

      eventSink.success(event);
    }
  }
}



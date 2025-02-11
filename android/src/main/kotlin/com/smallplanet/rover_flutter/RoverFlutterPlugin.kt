package com.smallplanet.rover_flutter

import android.content.Context
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity

import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.smallplanet.roverandroid.Rover
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

fun rerror(result: Result, error: String) {
  result.error("Rover Error", error, null)
}


class RoverFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var fragmentManager: FragmentManager? = null


  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "smallplanet.com/rover_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    fragmentManager = (binding.activity as? FragmentActivity)?.supportFragmentManager
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    fragmentManager = (binding.activity as? FragmentActivity)?.supportFragmentManager
  }

  override fun onDetachedFromActivity() {
    fragmentManager = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    fragmentManager = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "version") {
      result.success(Rover.version)
    } else if (call.method == "coreVersion") {
      result.success(Rover.coreVersion)
    } else if (call.method == "configure") {
      configure(call, result)
    } else {
      result.notImplemented()
    }
  }

  fun configure(call: MethodCall,
                result: Result) {
    val fragmentManager = fragmentManager ?: return rerror(result, "Fragment manager not found")

    data class Args(var licenseKey: String,
                    var environment: String,
                    var deviceId: String?,
                    var clearAndroidWebStorage: Boolean?,
                    var maxConcurrentCollections: Long?)

    val argsJson = (call.arguments as? String) ?: return rerror(result, "rover method called with non-String argument")

    val args = RNRJsonAny.parse(argsJson, Args::class.java) ?: return rerror(result, RNRJsonAny.parseError(argsJson, Args::class.java))

    val roverEnvironment = when(args.environment) {
      Rover.Environment.staging.rawValue -> Rover.Environment.staging
      Rover.Environment.production.rawValue -> Rover.Environment.production
      else -> return rerror(result, "Unknown environment: ${args.environment}")
    }

    Rover.configure(
      licenseKey = args.licenseKey,
      environment = roverEnvironment,
      deviceId = args.deviceId ?: "unknown",
      clearAndroidWebStorage = args.clearAndroidWebStorage ?: true,
      maxConcurrentCollections = args.maxConcurrentCollections ?: 4,
      context = applicationContext,
      supportFragmentManager = fragmentManager) callback@{ merchants, error ->
      if (error != null) {
        return@callback rerror(result, error)
      }
      val resultJson = RNRJsonAny.toJson(merchants) ?:
      return@callback rerror(result, "Failed to serialize merchants")
      result.success(resultJson)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

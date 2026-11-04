package com.smallplanet.rover_flutter

import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity

import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import androidx.work.ListenableWorker

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.smallplanet.roverandroid.Connection
import com.smallplanet.roverandroid.Rover
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.delay
import java.util.ArrayList
import java.util.Date
import java.util.UUID

fun rerror(result: Result, error: String) {
  result.error("Rover Error", error, null)
}

typealias ResponseBlock = (String?, String?) -> Unit

class RoverFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var fragmentManager: FragmentManager? = null

  private var waitingForResponseFromDelegate: HashMap<String, ResponseBlock> = hashMapOf()
  private var delegates: HashMap<String, NativeRoverDelegate> = hashMapOf()

  private val mainHandler = Handler(Looper.getMainLooper())


  companion object {
    const val TASK_IDENTIFIER = "com.smallplanet.rover.processing"

    private val pendingGlobalSend = mutableListOf<String>()
    private var pendingGlobalSendDidUpdate: () -> Unit = { }
    private var dartDidScheduleBackgroundCollections = false

    fun getPackageName(): String? {
      return Rover.getPackageName()
    }

    fun getPackageManager(appPackageName: String,
                          appPackageManager: PackageManager): PackageManager? {
      return Rover.getPackageManager(appPackageName, appPackageManager)
    }

    fun initBackgroundCollection(applicationContext: Context) {
      if (FlutterEngineCache.getInstance().get(TASK_IDENTIFIER) == null) {
        val engine = FlutterEngine(applicationContext)

        // Register plugins before running Dart so channels are ready.
        if (!engine.plugins.has(RoverFlutterPlugin::class.java)) {
          engine.plugins.add(RoverFlutterPlugin())
        }

        val loader = FlutterInjector.instance().flutterLoader()
        engine.dartExecutor.executeDartEntrypoint(
          DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "scheduleBackgroundCollections")
        )

        FlutterEngineCache.getInstance().put(TASK_IDENTIFIER, engine)
      }
    }

    suspend fun scheduleBackgroundCollections(context: Context): ListenableWorker.Result {
      // wait for the Dart side to be ready
      val deadline = SystemClock.elapsedRealtime() + 30000
      while (true) {
        var ready = false
        synchronized(pendingGlobalSend) {
          ready = dartDidScheduleBackgroundCollections
        }
        if (ready) {
          break
        }
        val remaining = deadline - SystemClock.elapsedRealtime()
        if (remaining <= 0) {
          return ListenableWorker.Result.failure()
        }
        delay(minOf(250L, remaining))
      }

      return Rover.scheduleBackgroundCollections(collectionWillStart = {
        data class ArgsStart(
          var taskIdentifier: String,
        )
        val args = ArgsStart(TASK_IDENTIFIER)
        val argsJson = RNRJsonAny.toJson(args) ?: return@scheduleBackgroundCollections
        synchronized(pendingGlobalSend) {
          pendingGlobalSend.add(argsJson)
        }
        pendingGlobalSendDidUpdate()
      }, collectionWillFinish = { connections ->
        data class ArgsFinish(
          var taskIdentifier: String,
          var connections: List<Connection>
        )
        val args = ArgsFinish(TASK_IDENTIFIER, connections)
        val argsJson = RNRJsonAny.toJson(args) ?: return@scheduleBackgroundCollections
        synchronized(pendingGlobalSend) {
          pendingGlobalSend.add(argsJson)
        }
        pendingGlobalSendDidUpdate()
      })
    }
  }

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

  fun newUUID(): String {
    return UUID.randomUUID().toString().uppercase()
  }

  fun remove(delegateUUID: String) {
    delegates.remove(delegateUUID)
  }

  fun send(delegateUUID: String,
           argsJson: String,
           returnCallback: ResponseBlock) {
    val hookUUID = newUUID()
    waitingForResponseFromDelegate[hookUUID] = returnCallback
    mainHandler.post {
      channel.invokeMethod(
        "callDelegate",
        mutableMapOf("hookUUID" to hookUUID, "delegateUUID" to delegateUUID, "argsJson" to argsJson)
      )
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "version") {
      result.success(Rover.version)
    } else if (call.method == "coreVersion") {
      result.success(Rover.coreVersion)
    } else if (call.method == "configure") {
      configure(call, result)
    } else if (call.method == "featureFlags") {
      featureFlags(call, result)
    } else if (call.method == "collect") {
      collect(call, result)
    } else if (call.method == "cancel") {
      cancel(call, result)
    } else if (call.method == "cancelAll") {
      cancelAll(call, result)
    } else if (call.method == "preconfig") {
      preconfig(call, result)
    } else if (call.method == "connections") {
      connections(call, result)
    } else if (call.method == "remove") {
      remove(call, result)
    } else if (call.method == "sendResult") {
      sendResult(call, result)
    } else if (call.method == "didScheduleBackgroundCollections") {
      didScheduleBackgroundCollections(result)
    } else {
      result.notImplemented()
    }
  }

  fun didScheduleBackgroundCollections(result: Result) {
    synchronized(pendingGlobalSend) {
      dartDidScheduleBackgroundCollections = true
      pendingGlobalSendDidUpdate = {
        mainHandler.post {

          val events: List<String>
          synchronized(pendingGlobalSend) {
            events = ArrayList(pendingGlobalSend)
            pendingGlobalSend.clear()
          }
          for (event in events) {
            try {
              channel.invokeMethod("callBackgroundCollection", mutableMapOf("argsJson" to event))
            } catch (e: Exception) {
              // engine is no longer attached; drop the event
              Log.d("ROVER", "exception in didScheduleBackgroundCollections: ${e}")
            }
          }
        }
      }
    }
    pendingGlobalSendDidUpdate()
    result.success(null)
  }

  fun sendResult(call: MethodCall,
                   result: Result) {
    data class Args(var hookUUID: String,
                    var delegateUUID: String,
                    var resultJson: String?,
                    var resultError: String?)

    val argsJson = (call.arguments as? String) ?:
      return rerror(result, "rover method called with non-String argument")

    val args = RNRJsonAny.parse(argsJson, Args::class.java) ?:
      return rerror(result, RNRJsonAny.parseError(argsJson, Args::class.java))

    val pendingResult = waitingForResponseFromDelegate[args.hookUUID] ?:
      return rerror(result, "hookUUID ${args.hookUUID} is not waiting for a response")

    waitingForResponseFromDelegate.remove(args.hookUUID)

    pendingResult(args.resultJson, args.resultError)

    result.success(null)
  }

  fun featureFlags(call: MethodCall,
                   result: Result) {
    val resultJson = RNRJsonAny.toJson(Rover.featureFlags) ?:
    return rerror(result, "Failed to serialize merchants")
    result.success(resultJson)
  }

  fun configure(call: MethodCall,
                result: Result) {
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

  fun collect(call: MethodCall,
              result: Result) {
    data class Args(
      var delegateUUID: String?,
      var userId: String?,
      var account: String?,
      var password: String?,
      var cookiesBase64: String?,
      var merchantId: Long,
      var javascript: ByteArray?,
      var javascriptUrl: String?,
      var javascriptVersion: Long?,
      var fromDate: Date,
      var toDate: Date?,
      var tier1BatchSize: Long?,
      var tier2BatchSize: Long?,
      var tier3BatchSize: Long?,
      var receiptsBatchSize: Long?,
      var collectItemInfo: Boolean?,
      var collectSourceData: Boolean?,
      var isEphemeral: Boolean?,
      var hasBackend: Boolean?,
      var allowUserInteractionRequired: Boolean?,
      var appInfo: String?,
      var featureFlags: MutableList<String>?,
      var overrideMimicDesktopIfPossible: Boolean?,
      var overrideWebviewBlockImageLoading: Boolean?
    )
    val argsJson = (call.arguments as? String) ?: return rerror(result, "rover method called with non-String argument")

    val args = RNRJsonAny.parse(argsJson, Args::class.java) ?: return rerror(result, RNRJsonAny.parseError(argsJson, Args::class.java))

    val delegateUUID = args.delegateUUID ?: return rerror(result, "missing delegate uuid")
    if (delegateUUID.isEmpty()) {
      return rerror(result, "invalid delegate uuid")
    }
    if (delegates[delegateUUID] != null) {
      return rerror(result, "delegateUUID $delegateUUID already exists")
    }

    val delegate = NativeRoverDelegate(
      uuid = delegateUUID,
      nativeRover = this
    )

    delegates[delegateUUID] = delegate

    Rover.collect(
      userId = args.userId,
      account = args.account,
      password = args.password,
      cookiesBase64 = args.cookiesBase64,
      merchantId = args.merchantId,
      javascript = args.javascript,
      javascriptUrl = args.javascriptUrl,
      javascriptVersion = args.javascriptVersion,
      fromDate = args.fromDate,
      toDate = args.toDate,
      serviceGroupRequests = null,
      tier1BatchSize = args.tier1BatchSize ?: 16,
      tier2BatchSize = args.tier2BatchSize ?: 16,
      tier3BatchSize = args.tier3BatchSize ?: 16,
      receiptsBatchSize = args.receiptsBatchSize ?: 8,
      collectItemInfo = args.collectItemInfo ?: false,
      collectSourceData = args.collectSourceData ?: false,
      isEphemeral = args.isEphemeral ?: false,
      hasBackend = args.hasBackend ?: false,
      allowUserInteractionRequired = args.allowUserInteractionRequired ?: true,
      appInfo = args.appInfo,
      featureFlags = args.featureFlags,
      overrideMimicDesktopIfPossible = args.overrideMimicDesktopIfPossible,
      overrideWebviewBlockImageLoading = args.overrideWebviewBlockImageLoading,
      delegate = delegate
    )

    result.success(null)
  }

  fun cancel(call: MethodCall,
             result: Result) {
    data class Args(
      var sessionUUID: String
    )
    val argsJson = (call.arguments as? String) ?: return rerror(result, "rover method called with non-String argument")
    val args = RNRJsonAny.parse(argsJson, Args::class.java) ?: return rerror(result, RNRJsonAny.parseError(argsJson, Args::class.java))

    Rover.cancel(sessionUUID = args.sessionUUID) callback@{ error ->
      if (error != null) {
        return@callback rerror(result, error)
      }
      return@callback result.success(null)
    }
  }

  fun cancelAll(call: MethodCall,
                result: Result) {
    Rover.cancelAll() callback@{ error ->
      if (error != null) {
        return@callback rerror(result, error)
      }
      return@callback result.success(null)
    }
  }

  fun preconfig(call: MethodCall,
                result: Result) {
    data class Args(
      var delegateUUID: String?,
      var userId: String?,
      var merchantId: Long?,
      var javascript: ByteArray?,
      var javascriptUrl: String?,
      var javascriptVersion: Long?
    )
    val argsJson = (call.arguments as? String) ?: return rerror(result, "rover method called with non-String argument")
    val args = RNRJsonAny.parse(argsJson, Args::class.java) ?: return rerror(result, RNRJsonAny.parseError(argsJson, Args::class.java))

    val delegateUUID = args.delegateUUID ?: return rerror(result, "missing delegate uuid")
    if (delegateUUID.isEmpty()) {
      return rerror(result, "invalid delegate uuid")
    }
    if (delegates[delegateUUID] != null) {
      return rerror(result,"delegateUUID $delegateUUID already exists")
    }

    val delegate = NativeRoverDelegate(
      uuid = delegateUUID,
      nativeRover = this
    )

    Rover.preconfig(
      userId = args.userId,
      merchantId = args.merchantId,
      javascript = args.javascript,
      javascriptUrl = args.javascriptUrl,
      javascriptVersion = args.javascriptVersion,
      delegate = delegate
    ) callback@{ resultJson, error ->
      if (error != null) {
        return@callback rerror(result, error)
      }
      return@callback result.success(resultJson)
    }
  }

  fun connections(call: MethodCall,
                  result: Result) {
    Rover.connections callback@{ connections ->
      val connectionsJson = RNRJsonAny.toJson(connections) ?:
      return@callback rerror(result, "Failed to serialize connections")
      return@callback result.success(connectionsJson)
    }
  }

  fun remove(call: MethodCall,
             result: Result) {
    data class Args(
      var account: String,
      var merchantId: Long
    )
    val argsJson = (call.arguments as? String) ?: return rerror(result, "rover method called with non-String argument")
    val args = RNRJsonAny.parse(argsJson, Args::class.java) ?: return rerror(result, RNRJsonAny.parseError(argsJson, Args::class.java))

    Rover.remove(
      account = args.account,
      merchantId = args.merchantId) callback@{
      return@callback result.success(null)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

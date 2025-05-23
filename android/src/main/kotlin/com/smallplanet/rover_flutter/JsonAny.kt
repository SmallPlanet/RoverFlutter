package com.smallplanet.rover_flutter

import android.util.Base64
import com.google.gson.*
import com.google.gson.JsonParseException
import java.lang.Byte.decode
import java.lang.reflect.Type
import java.text.SimpleDateFormat
import java.util.*
import com.smallplanet.roverandroid.Rover

class RNRJsonAny {
    companion object {
        
        val gson = GsonBuilder()
            .disableHtmlEscaping()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ssZZZZZ")
            .registerTypeAdapter(Date::class.java, JsonSerializer<Date>() { src, type, context ->
                return@JsonSerializer JsonPrimitive(Rover.dateFormatter.format(src))
            })
            .registerTypeAdapter(ByteArray::class.java, JsonSerializer<ByteArray>() { src, _, _ ->
                return@JsonSerializer JsonPrimitive(Base64.encodeToString(src, Base64.NO_WRAP))
            })
            .registerTypeAdapter(ByteArray::class.java, JsonDeserializer { json, _, _ ->
                Base64.decode(json.asString, Base64.NO_WRAP)
            })
            .create()

        fun <T> parse(json: String, classOfT: Class<T>): T? {
            return gson.fromJson(json, classOfT)
        }
        fun <T> parseError(json: String, classOfT: Class<T>): String {
          return try {
            gson.fromJson(json, classOfT)
            "unknown error"
          } catch (e: Exception) {
            e.message.toString()
          }
        }

        fun toJson(obj: JsonObject): String? {
            return gson.toJson(obj)
        }

        fun toJson(obj: Any): String? {
            return gson.toJson(obj)
        }

        fun toJson(obj: Any, error: String): String {
            val errorNoQuotes = error.replace("\"", "'")
            return gson.toJson(obj) ?: "{\"error\":\"${errorNoQuotes}\"}"
        }
    }
}

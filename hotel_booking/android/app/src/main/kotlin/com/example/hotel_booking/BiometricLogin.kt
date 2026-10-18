package com.example.hotel_booking

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/** Private signing keys require fresh strong biometric authorization for each signature. */
class BiometricLogin(private val activity: FragmentActivity) : MethodChannel.MethodCallHandler {
    private var pending = false
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            if (call.method == "available") {
                result.success(BiometricManager.from(activity).canAuthenticate(
                    BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS)
                return
            }
            val id = call.argument<String>("device_id") ?: ""
            require(Regex("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}").matches(id))
            val alias = "tetra-signin-$id"
            val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            when (call.method) {
                "create" -> {
                    require(!store.containsAlias(alias))
                    val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
                        .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                        .setDigests(KeyProperties.DIGEST_SHA256)
                        .setUserAuthenticationRequired(true)
                        .setInvalidatedByBiometricEnrollment(true)
                    if (Build.VERSION.SDK_INT >= 30) {
                        spec.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                    } else {
                        @Suppress("DEPRECATION")
                        spec.setUserAuthenticationValidityDurationSeconds(-1)
                    }
                    val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
                    generator.initialize(spec.build())
                    result.success(Base64.encodeToString(generator.generateKeyPair().public.encoded, Base64.NO_WRAP))
                }
                "delete" -> { store.deleteEntry(alias); result.success(null) }
                "sign" -> {
                    if (pending) { result.error("BUSY", "Đang xác thực vân tay", null); return }
                    val message = call.argument<String>("message") ?: ""
                    require(message.length <= 512 && (message.startsWith("TETRA:LOGIN:$id:") || message.startsWith("TETRA:ENROLL:$id:")))
                    val privateKey = store.getKey(alias, null) as? java.security.PrivateKey
                        ?: throw java.security.InvalidKeyException()
                    val signature = Signature.getInstance("SHA256withECDSA").apply {
                        initSign(privateKey)
                    }
                    pending = true
                    val prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity),
                        object : BiometricPrompt.AuthenticationCallback() {
                            override fun onAuthenticationSucceeded(auth: BiometricPrompt.AuthenticationResult) {
                                if (!pending) return
                                pending = false
                                try {
                                    val authorized = auth.cryptoObject?.signature
                                        ?: throw java.security.InvalidKeyException()
                                    authorized.update(message.toByteArray(Charsets.UTF_8))
                                    val signed = authorized.sign()
                                    result.success(Base64.encodeToString(signed, Base64.NO_WRAP))
                                } catch (_: Exception) { result.error("KEY_INVALID", "Hãy bật lại đăng nhập vân tay", null) }
                            }
                            override fun onAuthenticationError(code: Int, message: CharSequence) {
                                if (!pending) return
                                pending = false
                                result.error("BIOMETRIC_CANCELLED", "Chưa xác thực vân tay; bạn có thể dùng mật khẩu", null)
                            }
                        })
                    val info = BiometricPrompt.PromptInfo.Builder()
                        .setTitle("Đăng nhập TETRA bằng vân tay")
                        .setSubtitle("Dùng sinh trắc học đã đăng ký trên điện thoại")
                        .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                        .setNegativeButtonText("Dùng mật khẩu").build()
                    prompt.authenticate(info, BiometricPrompt.CryptoObject(signature))
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            pending = false
            result.error("KEY_INVALID", "Thiết bị chưa sẵn sàng. Dùng mật khẩu rồi bật lại vân tay", null)
        }
    }
}

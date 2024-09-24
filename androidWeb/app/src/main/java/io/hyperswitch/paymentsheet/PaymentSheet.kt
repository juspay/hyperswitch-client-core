package io.hyperswitch.paymentsheet

import android.content.res.ColorStateList
import android.os.Parcelable
import androidx.annotation.ColorInt
import androidx.annotation.FontRes
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.hyperswitch.paymentsheet.DefaultPaymentSheetLauncher.Companion.getRGBAHex
import kotlinx.parcelize.Parcelize

/**
 * A drop-in class that presents a bottom sheet to collect and process a customer's payment.
 */
class PaymentSheet internal constructor(
    private val paymentSheetLauncher: PaymentSheetLauncher
) {

    /**
     * Constructor to be used when launching the payment sheet from an Activity.
     *
     * @param activity  the Activity that is presenting the payment sheet.
     * @param callback  called with the result of the payment after the payment sheet is dismissed.
     */
    constructor(
        activity: FragmentActivity,
        callback: PaymentSheetResultCallback
    ) : this(
        DefaultPaymentSheetLauncher(activity, callback)
    )

    /**
     * Constructor to be used when launching the payment sheet from a Fragment.
     *
     * @param fragment the Fragment that is presenting the payment sheet.
     * @param callback called with the result of the payment after the payment sheet is dismissed.
     */
    constructor(
        fragment: Fragment,
        callback: PaymentSheetResultCallback
    ) : this(
        DefaultPaymentSheetLauncher(fragment, callback)
    )

    /**
     * Present the payment sheet to process a [PaymentIntent].
     * If the [PaymentIntent] is already confirmed, [PaymentSheetResultCallback] will be invoked
     * with [PaymentSheetResult.Completed].
     *
     * @param paymentIntentClientSecret the client secret for the [PaymentIntent].
     * @param configuration optional [PaymentSheet] settings.
     */
    @JvmOverloads
    fun presentWithPaymentIntent(
        paymentIntentClientSecret: String,
        configuration: Configuration? = null
    ) {
        paymentSheetLauncher.presentWithPaymentIntent(paymentIntentClientSecret, configuration)

    }

    @JvmOverloads
    fun presentWithPaymentIntentAndParams(
        map: Map<String, Any?>,
        sheetType: String? = null
    ) {
        paymentSheetLauncher.presentWithPaymentIntentAndParams(map, sheetType)

    }

    @JvmOverloads
    fun presentWithNewPaymentIntent(
        paymentIntentClientSecret: String,
        configuration: Configuration? = null
    ) {
        paymentSheetLauncher.presentWithNewPaymentIntent(paymentIntentClientSecret, configuration)

    }

    /**
     * Present the payment sheet to process a [SetupIntent].
     * If the [SetupIntent] is already confirmed, [PaymentSheetResultCallback] will be invoked
     * with [PaymentSheetResult.Completed].
     *
     * @param setupIntentClientSecret the client secret for the [SetupIntent].
     * @param configuration optional [PaymentSheet] settings.
     */
    @JvmOverloads
    fun presentWithSetupIntent(
        setupIntentClientSecret: String,
        configuration: Configuration? = null
    ) {
        paymentSheetLauncher.presentWithSetupIntent(setupIntentClientSecret, configuration)
    }


    /** Configuration for [PaymentSheet] **/
    @Parcelize
    data class Configuration @JvmOverloads constructor(
        /**
         * Your customer-facing business name.
         *
         * The default value is the name of your app.
         */
        val merchantDisplayName: String,

        /**
         * If set, the customer can select a previously saved payment method within PaymentSheet.
         */
        val customer: CustomerConfiguration? = null,

        /**
         * Configuration related to the Hyperswitch Customer making a payment.
         *
         * If set, PaymentSheet displays Google Pay as a payment option.
         */
        val googlePay: GooglePayConfiguration? = null,

        /**
         * The color of the Pay or Add button. Keep in mind the text color is white.
         *
         * If set, PaymentSheet displays the button with this color.
         */
        @Deprecated(
            message = "Use Appearance parameter to customize primary button color",
            replaceWith = ReplaceWith(
                expression = "Appearance.colorsLight/colorsDark.primary " +
                        "or PrimaryButton.colorsLight/colorsDark.background"
            )
        )
        val primaryButtonColor: ColorStateList? = null,

        /**
         * The billing information for the customer.
         *
         * If set, PaymentSheet will pre-populate the form fields with the values provided.
         */
        val defaultBillingDetails: BillingDetails? = null,

        /**
         * The shipping information for the customer.
         * If set, PaymentSheet will pre-populate the form fields with the values provided.
         * This is used to display a "Billing address is same as shipping" checkbox if `defaultBillingDetails` is not provided.
         * If `name` and `line1` are populated, it's also [attached to the PaymentIntent](https://docs.hyperswitch.io//api/payment_intents/object#payment_intent_object-shipping) during payment.
         */
        val shippingDetails: AddressDetails? = null,

        /**
         * If true, allows payment methods that do not move money at the end of the checkout.
         * Defaults to false.
         *
         * Some payment methods can't guarantee you will receive funds from your customer at the end
         * of the checkout because they take time to settle (eg. most bank debits, like SEPA or ACH)
         * or require customer action to complete (e.g. OXXO, Konbini, Boleto). If this is set to
         * true, make sure your integration listens to webhooks for notifications on whether a
         * payment has succeeded or not.
         *
         * See [payment-notification](https://docs.hyperswitch.io//payments/payment-methods#payment-notification).
         */
        val allowsDelayedPaymentMethods: Boolean = false,
        val displaySavedPaymentMethodsCheckbox: Boolean = true,
        val displaySavedPaymentMethods: Boolean = true,
        val placeHolder: PlaceHolder? = null,

        /**
         * If `true`, allows payment methods that require a shipping address, like Afterpay and
         * Affirm. Defaults to `false`.
         *
         * Set this to `true` if you collect shipping addresses via [shippingDetails] or
         * [FlowController.shippingDetails].
         *
         * **Note**: PaymentSheet considers this property `true` if `shipping` details are present
         * on the PaymentIntent when PaymentSheet loads.
         */
        val allowsPaymentMethodsRequiringShippingAddress: Boolean = false,

        /**
         * Describes the appearance of Payment Sheet.
         */
        val appearance: Appearance? = null,

        /**
         * The label to use for the primary button.
         *
         * If not set, Payment Sheet will display suitable default labels for payment and setup
         * intents.
         */
        val primaryButtonLabel: String? = null,
        val paymentSheetHeaderLabel: String? = null,
        val savedPaymentSheetHeaderLabel: String? = null,
        val displayDefaultSavedPaymentIcon: Boolean? = null,
        /**
         * Api key used to invoke netcetera sdk for redirection-less 3DS authentication.
         */
        val netceteraSDKApiKey: String? = null,
        val disableBranding: Boolean? = null,
        val defaultView: Boolean? = null,
    ) : Parcelable {
        /**
         * [Configuration] builder for cleaner object creation from Java.
         */
        class Builder(
            private var merchantDisplayName: String
        ) {
            private var customer: CustomerConfiguration? = null
            private var googlePay: GooglePayConfiguration? = null
            private var primaryButtonColor: ColorStateList? = null
            private var defaultBillingDetails: BillingDetails? = null
            private var shippingDetails: AddressDetails? = null
            private var allowsDelayedPaymentMethods: Boolean = false
            private var displaySavedPaymentMethodsCheckbox: Boolean = true
            private var displaySavedPaymentMethods: Boolean = true
            private var placeHolder: PlaceHolder? = null
            private var allowsPaymentMethodsRequiringShippingAddress: Boolean = false
            private var appearance: Appearance? = null
            private var primaryButtonLabel: String? = null
            private var disableBranding: Boolean? = null
            private var defaultView: Boolean? = null
            private var displayDefaultSavedPaymentIcon: Boolean? = null
            private var paymentSheetHeaderLabel: String? = null
            private var savedPaymentSheetHeaderLabel: String? = null
            private var netceteraSDKApiKey: String? = null
            fun merchantDisplayName(merchantDisplayName: String) =
                apply { this.merchantDisplayName = merchantDisplayName }

            fun customer(customer: CustomerConfiguration?) =
                apply { this.customer = customer }

            fun googlePay(googlePay: GooglePayConfiguration?) =
                apply { this.googlePay = googlePay }

            @Deprecated(
                message = "Use Appearance parameter to customize primary button color",
                replaceWith = ReplaceWith(
                    expression = "Appearance.colorsLight/colorsDark.primary " +
                            "or PrimaryButton.colorsLight/colorsDark.background"
                )
            )
            fun primaryButtonColor(primaryButtonColor: ColorStateList?) =
                apply { this.primaryButtonColor = primaryButtonColor }

            fun defaultBillingDetails(defaultBillingDetails: BillingDetails?) =
                apply { this.defaultBillingDetails = defaultBillingDetails }

            fun shippingDetails(shippingDetails: AddressDetails?) =
                apply { this.shippingDetails = shippingDetails }

            fun allowsDelayedPaymentMethods(allowsDelayedPaymentMethods: Boolean) =
                apply { this.allowsDelayedPaymentMethods = allowsDelayedPaymentMethods }

            fun displaySavedPaymentMethodsCheckbox(displaySavedPaymentMethodsCheckbox: Boolean) =
                apply { this.displaySavedPaymentMethodsCheckbox = displaySavedPaymentMethodsCheckbox }

            fun displaySavedPaymentMethods(displaySavedPaymentMethods: Boolean) =
                apply { this.displaySavedPaymentMethods = displaySavedPaymentMethods }

            fun placeHolder(placeHolder: PlaceHolder?) =
                apply { this.placeHolder = placeHolder }

            fun allowsPaymentMethodsRequiringShippingAddress(
                allowsPaymentMethodsRequiringShippingAddress: Boolean,
            ) = apply {
                this.allowsPaymentMethodsRequiringShippingAddress =
                    allowsPaymentMethodsRequiringShippingAddress
            }

            fun appearance(appearance: Appearance) =
                apply { this.appearance = appearance }

            fun primaryButtonLabel(primaryButtonLabel: String) =
                apply { this.primaryButtonLabel = primaryButtonLabel }

            fun disableBranding(disableBranding: Boolean) =
                apply { this.disableBranding = disableBranding }

            fun defaultView(defaultView: Boolean) =
                apply { this.defaultView = defaultView }

            fun displayDefaultSavedPaymentIcon(displayDefaultSavedPaymentIcon: Boolean) =
                apply { this.displayDefaultSavedPaymentIcon = displayDefaultSavedPaymentIcon }

            fun paymentSheetHeaderLabel(paymentSheetHeaderLabel: String) =
                apply { this.paymentSheetHeaderLabel = paymentSheetHeaderLabel }

            fun netceteraSDKApiKey(netceteraSDKApiKey: String?) = apply {
                this.netceteraSDKApiKey = netceteraSDKApiKey
            }
            fun savedPaymentSheetHeaderLabel(savedPaymentSheetHeaderLabel: String) =
                apply { this.savedPaymentSheetHeaderLabel = savedPaymentSheetHeaderLabel }

            fun build() = Configuration(
                merchantDisplayName,
                customer,
                googlePay,
                primaryButtonColor,
                defaultBillingDetails,
                shippingDetails,
                allowsDelayedPaymentMethods,
                displaySavedPaymentMethodsCheckbox,
                displaySavedPaymentMethods,
                placeHolder,
                allowsPaymentMethodsRequiringShippingAddress,
                appearance,
                primaryButtonLabel,
                paymentSheetHeaderLabel,
                savedPaymentSheetHeaderLabel,
                displayDefaultSavedPaymentIcon,
                netceteraSDKApiKey,
            )
        }

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "merchantDisplayName" to merchantDisplayName,
                "customer" to (customer?.getMap()),
                "googlePay" to (googlePay?.getMap()),
                "defaultBillingDetails" to defaultBillingDetails?.getMap(),
                "shippingDetails" to shippingDetails?.getMap(),
                "allowsDelayedPaymentMethods" to allowsDelayedPaymentMethods,
                "displaySavedPaymentMethodsCheckbox" to displaySavedPaymentMethodsCheckbox,
                "displaySavedPaymentMethods" to displaySavedPaymentMethods,
                "placeholder" to placeHolder?.getMap(),
                "appearance" to appearance?.getMap(),
                "primaryButtonLabel" to primaryButtonLabel,
                "paymentSheetHeaderLabel" to paymentSheetHeaderLabel,
                "savedPaymentSheetHeaderLabel" to savedPaymentSheetHeaderLabel,
                "netceteraSDKApiKey" to netceteraSDKApiKey,
                "allowsPaymentMethodsRequiringShippingAddress" to allowsPaymentMethodsRequiringShippingAddress,
                "displayDefaultSavedPaymentIcon" to displayDefaultSavedPaymentIcon
            )
        }
    }

    @Parcelize
    data class Appearance(
        /**
         * Describes the colors used while the system is in light mode.
         */
        val colorsLight: Colors?= null,

        /**
         * Describes the colors used while the system is in dark mode.
         */
        val colorsDark: Colors?= null,

        /**
         * Describes the appearance of shapes.
         */
        val shapes: Shapes?= null,

        /**
         * Describes the typography used for text.
         */
        val typography: Typography?= null,

        /**
         * Describes the appearance of the primary button (e.g., the "Pay" button).
         */
        val primaryButton: PrimaryButton?= null,

        val locale: String?= null,

        val theme: Theme?= null
    ) : Parcelable {
        class Builder {
            private var colorsLight: Colors?= null
            private var colorsDark: Colors?= null
            private var shapes: Shapes?= null
            private var theme: Theme?= null
            private var typography: Typography?= null
            private var locale: String?= null
            private var primaryButton: PrimaryButton?= null

            fun colorsLight(colors: Colors) = apply { this.colorsLight = colors }
            fun colorsDark(colors: Colors) = apply { this.colorsDark = colors }
            fun shapes(shapes: Shapes) = apply { this.shapes = shapes }
            fun theme(theme: Theme) = apply { this.theme = theme }
            fun locale(locale: String) = apply { this.locale = locale }
            fun typography(typography: Typography) = apply { this.typography = typography }
            fun primaryButton(primaryButton: PrimaryButton) = apply { this.primaryButton = primaryButton }

            fun build() = Appearance(
                colorsLight,
                colorsDark,
                shapes,
                typography,
                primaryButton,
                locale,
                theme,
            )

        }

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "colorsLight" to colorsLight?.getMap(),
                "colorsDark" to colorsDark?.getMap(),
                "shapes" to shapes?.getMap(),
                "theme" to theme.toString(),
                "locale" to locale,
                "typography" to typography?.getMap(),
                "primaryButton" to primaryButton?.getMap()
            )
        }
    }


    @Parcelize
    data class Colors(
        /**
         * A primary color used throughout PaymentSheet.
         */
        @ColorInt
        val primary: Int?= null,

        /**
         * The color used for the surfaces (backgrounds) of PaymentSheet.
         */
        @ColorInt
        val surface: Int? = null,

        /**
         * The color used for the background of inputs, tabs, and other components.
         */
        @ColorInt
        val component: Int? = null,

        /**
         * The color used for borders of inputs, tabs, and other components.
         */
        @ColorInt
        val componentBorder: Int? = null,

        /**
         * The color of the divider lines used inside inputs, tabs, and other components.
         */
        @ColorInt
        val componentDivider: Int? = null,

        /**
         * The default color used for text and on other elements that live on components.
         */
        @ColorInt
        val onComponent: Int? = null,

        /**
         * The color used for items appearing over the background in Payment Sheet.
         */
        @ColorInt
        val onSurface: Int? = null,

        /**
         * The color used for text of secondary importance.
         * For example, this color is used for the label above input fields.
         */
        @ColorInt
        val subtitle: Int? = null,

        /**
         * The color used for input placeholder text.
         */
        @ColorInt
        val placeholderText: Int? = null,

        /**
         * The color used for icons in PaymentSheet, such as the close or back icons.
         */
        @ColorInt
        val appBarIcon: Int? = null,

        /**
         * A color used to indicate errors or destructive actions in PaymentSheet.
         */
        @ColorInt
        val error: Int? = null,

        /**
         * A color used to indicate Loader Background color in PaymentSheet.
         */
        @ColorInt
        val loaderBackground: Int? = null,

        /**
         * A color used to indicate Loader Foreground color in PaymentSheet.
         */
        @ColorInt
        val loaderForeground: Int? = null
    ) : Parcelable {
        constructor(
            primary: Color? = null,
            surface: Color? = null,
            component: Color? = null,
            componentBorder: Color? = null,
            componentDivider: Color? = null,
            onComponent: Color? = null,
            subtitle: Color? = null,
            placeholderText: Color? = null,
            onSurface: Color? = null,
            appBarIcon: Color? = null,
            error: Color? = null,
            loaderBackground: Color?,
            loaderForeground: Color?,
        ) : this(
            primary = primary?.toArgb(),
            surface = surface?.toArgb(),
            component = component?.toArgb(),
            componentBorder = componentBorder?.toArgb(),
            componentDivider = componentDivider?.toArgb(),
            onComponent = onComponent?.toArgb(),
            subtitle = subtitle?.toArgb(),
            placeholderText = placeholderText?.toArgb(),
            onSurface = onSurface?.toArgb(),
            appBarIcon = appBarIcon?.toArgb(),
            error = error?.toArgb(),
            loaderBackground = loaderBackground?.toArgb(),
            loaderForeground = loaderForeground?.toArgb(),
        )
        class Builder() {
            @ColorInt var primary: Int?= null
            @ColorInt var surface: Int? = null
            @ColorInt var component: Int? = null
            @ColorInt var componentBorder: Int? = null
            @ColorInt var componentDivider: Int? = null
            @ColorInt var onComponent: Int? = null
            @ColorInt var onSurface: Int? = null
            @ColorInt var subtitle: Int? = null
            @ColorInt var placeholderText: Int? = null
            @ColorInt var appBarIcon: Int? = null
            @ColorInt var error: Int? = null
            @ColorInt var loaderBackground: Int? = null
            @ColorInt var loaderForeground: Int? = null

            fun primary(primary: Int?) =
                apply { this.primary = primary }
            fun surface(surface: Int?) =
                apply { this.surface = surface }
            fun component(component: Int?) =
                apply { this.component = component }
            fun componentBorder(componentBorder: Int?) =
                apply { this.componentBorder = componentBorder }
            fun componentDivider(componentDivider: Int?) =
                apply { this.componentDivider = componentDivider }
            fun onComponent(onComponent: Int?) =
                apply { this.onComponent = onComponent }
            fun onSurface(onSurface: Int?) =
                apply { this.onSurface = onSurface }
            fun subtitle(subtitle: Int?) =
                apply { this.subtitle = subtitle }
            fun placeholderText(placeholderText: Int?) =
                apply { this.placeholderText = placeholderText }
            fun appBarIcon(appBarIcon: Int?) =
                apply { this.appBarIcon = appBarIcon }
            fun error(error: Int?) =
                apply { this.error = error }

            fun loaderBackground(loaderBackground: Int?) =
                apply { this.loaderBackground = loaderBackground }

            fun loaderForeground(loaderForeground: Int?) =
                apply { this.loaderForeground = loaderForeground }

            fun build() = Colors(
                primary,
                surface,
                component,
                componentBorder,
                componentDivider,
                onComponent,
                onSurface,
                subtitle,
                placeholderText,
                appBarIcon,
                error,
                loaderBackground,
                loaderForeground,
            )
        }

        fun getMap(): Map<String, Any?> {
            return mapOf(
            "primary" to getRGBAHex(primary),
            "surface" to getRGBAHex(surface),
            "component" to getRGBAHex(component),
            "componentBorder" to getRGBAHex(componentBorder),
            "componentDivider" to getRGBAHex(componentDivider),
            "onComponent" to getRGBAHex(onComponent),
            "subtitle" to getRGBAHex(subtitle),
            "placeholderText" to getRGBAHex(placeholderText),
            "onSurface" to getRGBAHex(onSurface),
            "appBarIcon" to getRGBAHex(appBarIcon),
            "error" to getRGBAHex(error),
            "loaderBackground" to getRGBAHex(loaderBackground),
            "loaderForeground" to getRGBAHex(loaderForeground),
            )
        }

    }

    @Parcelize
    data class Shadow(
        /**
         * The color used for setting Shadow color.
         */
        val color: Int?,

        /**
         * The intensity used for setting intensity of Shadow in PaymentSheet.
         */
        val intensity: Float?
    ) : Parcelable {
        constructor(
            color: Color?,
            intensity: Float?
        ) :this(
            color = color?.toArgb(),
            intensity = intensity
        )

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "color" to getRGBAHex(color),
                "intensity" to intensity
            )
        }
    }

    @Parcelize
    data class Shapes(
        /**
         * The corner radius used for tabs, inputs, buttons, and other components in PaymentSheet.
         */
        val cornerRadiusDp: Float?,

        /**
         * The border used for inputs, tabs, and other components in PaymentSheet.
         */
        val borderStrokeWidthDp: Float?,

        /**
         * The shadow used for inputs, tabs, and other components in PaymentSheet.
         */
        val shadow: Shadow?
    ) : Parcelable {
        fun getMap(): Map<String, Any?> {
            return mapOf(
                "cornerRadiusDp" to cornerRadiusDp,
                "borderStrokeWidthDp" to borderStrokeWidthDp,
                "shadow" to shadow?.getMap()
            )
        }
    }

    @Parcelize
    data class Typography(
        /**
         * The scale factor for all fonts in PaymentSheet, the default value is 1.0.
         * When this value increases fonts will increase in size and decrease when this value is lowered.
         */
        val sizeScaleFactor: Float?=null,

        /**
         * The font used in text. This should be a resource ID value.
         */
        @FontRes
        val fontResId: Int?=null
    ) : Parcelable {
        fun getMap(): Map<String, Any?> {
            return DefaultPaymentSheetLauncher.Typography(sizeScaleFactor, fontResId).getMap()
        }
    }

    @Parcelize
    data class PrimaryButton(
        /**
         * Describes the colors used while the system is in light mode.
         */
        var colorsLight: PrimaryButtonColors?=null,
        /**
         * Describes the colors used while the system is in dark mode.
         */
        val colorsDark: PrimaryButtonColors?= null,
        /**
         * Describes the shape of the primary button.
         */
        val shape: PrimaryButtonShape?=null,
        /**
         * Describes the typography of the primary button.
         */
        val typography: PrimaryButtonTypography?=null
    ) : Parcelable {

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "colorsLight" to colorsLight?.getMap(),
                "colorsDark" to colorsDark?.getMap(),
                "shapes" to shape?.getMap(),
                "typography" to typography?.getMap()
            )
        }
    }

    @Parcelize
    data class PrimaryButtonColors(
        /**
         * The background color of the primary button.
         * Note: If 'null', {@link Colors#primary} is used.
         */
        @ColorInt
        val background: Int?,
        /**
         * The color of the text and icon in the primary button.
         */
        @ColorInt
        val onBackground: Int,
        /**
         * The border color of the primary button.
         */
        @ColorInt
        val border: Int
    ) : Parcelable {
        constructor(
            background: Color?,
            onBackground: Color,
            border: Color
        ) : this(
            background = background?.toArgb(),
            onBackground = onBackground.toArgb(),
            border = border.toArgb()
        )

        fun getMap():Map<String, Any?>{
            return mapOf(
                "background" to getRGBAHex(background),
                "onBackground" to getRGBAHex(onBackground),
                "border" to getRGBAHex(border)
            )
        }
    }

    @Parcelize
    data class PrimaryButtonShape(
        /**
         * The corner radius of the primary button.
         * Note: If 'null', {@link Shapes#cornerRadiusDp} is used.
         */
        val cornerRadiusDp: Float? = null,
        /**
         * The border width of the primary button.
         * Note: If 'null', {@link Shapes#borderStrokeWidthDp} is used.
         */
        val borderStrokeWidthDp: Float? = null,
        /**
         * The shadow of the primary button.
         * Note: If 'null', {@link Shapes#borderStrokeWidthDp} is used.
         */
        val shadow: Shadow? = null
    ) : Parcelable {
        fun getMap(): Map<String, Any?> {
            return mapOf(
                "cornerRadiusDp" to cornerRadiusDp,
                "borderStrokeWidthDp" to borderStrokeWidthDp,
                "shadow" to shadow?.getMap()
            )
        }
    }

    @Parcelize
    data class PrimaryButtonTypography(
        /**
         * The font used in the primary button.
         * Note: If 'null', Appearance.Typography.fontResId is used.
         */
        @FontRes
        val fontResId: Int? = null,

        /**
         * The font size in the primary button.
         * Note: If 'null', {@link Typography#sizeScaleFactor} is used.
         */
        val fontSizeSp: Float? = null
    ) : Parcelable {
        fun getMap(): Map<String, Any?> {
            return mapOf(
                "fontSizeSp" to fontSizeSp,
                "fontResId" to fontResId.toString()
            )
        }
    }



    @Parcelize
    data class Address(
        /**
         * City, district, suburb, town, or village.
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val city: String? = null,
        /**
         * Two-letter country code (ISO 3166-1 alpha-2).
         */
        val country: String? = null,
        /**
         * Address line 1 (e.g., street, PO Box, or company name).
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val line1: String? = null,
        /**
         * Address line 2 (e.g., apartment, suite, unit, or building).
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val line2: String? = null,
        /**
         * ZIP or postal code.
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val postalCode: String? = null,
        /**
         * State, county, province, or region.
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val state: String? = null
    ) : Parcelable {
        /**
         * [Address] builder for cleaner object creation from Java.
         */
        class Builder {
            private var city: String? = null
            private var country: String? = null
            private var line1: String? = null
            private var line2: String? = null
            private var postalCode: String? = null
            private var state: String? = null

            fun city(city: String?) = apply { this.city = city }
            fun country(country: String?) = apply { this.country = country }
            fun line1(line1: String?) = apply { this.line1 = line1 }
            fun line2(line2: String?) = apply { this.line2 = line2 }
            fun postalCode(postalCode: String?) = apply { this.postalCode = postalCode }
            fun state(state: String?) = apply { this.state = state }

            fun build() = Address(city, country, line1, line2, postalCode, state)
        }

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "city" to city,
                "country" to country,
                "line1" to line1,
                "line2" to line2,
                "postalCode" to postalCode,
                "state" to state
            )
        }

    }

    @Parcelize
    data class BillingDetails(
        /**
         * The customer's billing address.
         */
        val address: Address? = null,
        /**
         * The customer's email.
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val email: String? = null,
        /**
         * The customer's full name.
         * The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
         */
        val name: String? = null,
        /**
         * The customer's phone number without formatting e.g. 5551234567
         */
        val phone: String? = null
    ) : Parcelable {
        /**
         * [BillingDetails] builder for cleaner object creation from Java.
         */
        class Builder {
            private var address: Address? = null
            private var email: String? = null
            private var name: String? = null
            private var phone: String? = null

            fun address(address: Address?) = apply { this.address = address }
            fun address(addressBuilder: Address.Builder) =
                apply { this.address = addressBuilder.build() }

            fun email(email: String?) = apply { this.email = email }
            fun name(name: String?) = apply { this.name = name }
            fun phone(phone: String?) = apply { this.phone = phone }

            fun build() = BillingDetails(address, email, name, phone)
        }

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "address" to address?.getMap(),
                "email" to email,
                "name" to name,
                "phone" to phone
            )
        }

    }

    @Parcelize
    data class CustomerConfiguration(
        /**
         * The identifier of the Hyperswitch Customer object.
         * See [Hyperswitch's documentation](https://docs.hyperswitch.io//api/customers/object#customer_object-id).
         */
        val id: String,

        /**
         * A short-lived token that allows the SDK to access a Customer's payment methods.
         */
        val ephemeralKeySecret: String
    ) : Parcelable {

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "id" to id,
                "ephemeralKeySecret" to ephemeralKeySecret
            )
        }

    }

    @Parcelize
    data class GooglePayConfiguration(
        /**
         * The Google Pay environment to use.
         *
         * See [Google's documentation](https://developers.google.com/android/reference/com/google/android/gms/wallet/Wallet.WalletOptions#environment) for more information.
         */
        val environment: Environment,
        /**
         * The two-letter ISO 3166 code of the country of your business, e.g. "US".
         * See your account's country value [here](https://app.hyperswitch.io/settings/account).
         */
        val countryCode: String,
        /**
         * The three-letter ISO 4217 alphabetic currency code, e.g. "USD" or "EUR".
         * Required in order to support Google Pay when processing a Setup Intent.
         */
        val currencyCode: String? = null
    ) : Parcelable {
        constructor(
            environment: Environment,
            countryCode: String
        ) : this(environment, countryCode, null)

        enum class Environment {
            Production,
            Test
        }

        fun getMap(): Map<String, Any?> {
            return mapOf(
                "environment" to environment.toString(),
                "countryCode" to countryCode,
                "currencyCode" to currencyCode
            )
        }

    }


    @Parcelize
    data class PlaceHolder(
        val cardNumber: String? = null,
        val expiryDate: String? = null,
        val cvv: String? = null
    ) : Parcelable {
        fun getMap(): Map<String, Any?> {
            return mapOf(
                "cardNumber" to cardNumber,
                "expiryDate" to expiryDate,
                "cvv" to cvv
            )
        }
    }

    /**
     * A class that presents the individual steps of a payment sheet flow.
     */
    interface FlowController {

        var shippingDetails: AddressDetails?

        var paymentIntentClientSecret: String
        var configuration: Configuration?

        /**
         * Configure the FlowController to process a [PaymentIntent].
         *
         * @param paymentIntentClientSecret the client secret for the [PaymentIntent].
         * @param configuration optional [PaymentSheet] settings.
         * @param callback called with the result of configuring the FlowController.
         */
        fun configureWithPaymentIntent(
            paymentIntentClientSecret: String,
            configuration: Configuration? = null,
            callback: ConfigCallback
        )

        /**
         * Configure the FlowController to process a [SetupIntent].
         *
         * @param setupIntentClientSecret the client secret for the [SetupIntent].
         * @param configuration optional [PaymentSheet] settings.
         * @param callback called with the result of configuring the FlowController.
         */
        fun configureWithSetupIntent(
            setupIntentClientSecret: String,
            configuration: Configuration? = null,
            callback: ConfigCallback
        )

        /**
         * Retrieve information about the customer's desired payment option.
         * You can use this to e.g. display the payment option in your UI.
         */
        fun getPaymentOption(): PaymentOption?

        /**
         * Present a sheet where the customer chooses how to pay, either by selecting an existing
         * payment method or adding a new one.
         * Call this when your "Select a payment method" button is tapped.
         */
        fun presentPaymentOptions()

        /**
         * Complete the payment or setup.
         */
        fun confirm()

        sealed class Result {
            object Success : Result()

            class Failure(
                val error: Throwable
            ) : Result()
        }

        fun interface ConfigCallback {
            fun onConfigured(
                success: Boolean,
                error: Throwable?
            )
        }

        companion object {

            /**
             * Create the FlowController when launching the payment sheet from an Activity.
             *
             * @param activity  the Activity that is presenting the payment sheet.
             * @param paymentOptionCallback called when the customer's desired payment method
             *      changes.  Called in response to the [PaymentSheet#presentPaymentOptions()]
             * @param paymentResultCallback called when a [PaymentSheetResult] is available.
             */
            @JvmStatic
            fun create(
                activity: FragmentActivity,
                paymentOptionCallback: PaymentOptionCallback,
                paymentResultCallback: PaymentSheetResultCallback
            ): FlowController {
                return FlowControllerFactory(
                    activity,
                    paymentOptionCallback,
                    paymentResultCallback
                ).create()
            }

            /**
             * Create the FlowController when launching the payment sheet from a Fragment.
             *
             * @param fragment the Fragment that is presenting the payment sheet.
             * @param paymentOptionCallback called when the customer's [PaymentOption] selection changes.
             * @param paymentResultCallback called when a [PaymentSheetResult] is available.
             */
            @JvmStatic
            fun create(
                fragment: Fragment,
                paymentOptionCallback: PaymentOptionCallback,
                paymentResultCallback: PaymentSheetResultCallback
            ) {
//                return FlowControllerFactory(
//                    fragment,
//                    paymentOptionCallback,
//                    paymentResultCallback
//                ).create()
            }
        }
    }
}

enum class Theme {
    Light,
    Dark,
    FlatMinimal,
    Minimal,
    Default,
}
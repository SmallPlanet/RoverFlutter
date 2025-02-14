// Codable Request/Reponse structures for communicating from the facade to RoverCore. RoveriOS and RoverServer can
// use these verbatim, but we use https://github.com/KittyMac/Transom to autotranslate to Kotlin data classes
// for RoverAndroid. Please keep the complexity of this file to a minimum, and if you encounter any compile
// errors report them to Rocco.

// typescript:
// typescript-ignore: ScrapeRequest
// typescript-ignore: ScrapeStatus
// typescript-ignore: ScrapeServiceGroupStatus
// typescript-ignore: MerchantId
// typescript-ignore: ServiceGroupRequest
// typescript-ignore: MerchantId
// typescript-ignore: InternalMerchantId

class ConnectionStruct {
  int merchantId;
  String account;
  String? password;
  String? cookiesBase64;
  DateTime? fromDate;
  String? appInfo;
  List<String>? featureFlags;
  bool userInteractionRequired;

  ConnectionStruct({
    required this.merchantId,
    required this.account,
    this.password,
    this.cookiesBase64,
    this.fromDate,
    this.appInfo,
    this.featureFlags,
    required this.userInteractionRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'account': account,
      'password': password,
      'cookiesBase64': cookiesBase64,
      'fromDate': fromDate?.toIso8601String(),
      'appInfo': appInfo,
      'featureFlags': featureFlags,
      'userInteractionRequired': userInteractionRequired,
    };
  }

  factory ConnectionStruct.fromJson(Map<String, dynamic> json) {
    return ConnectionStruct(
      merchantId: json['merchantId'],
      account: json['account'],
      password: json['password'],
      cookiesBase64: json['cookiesBase64'],
      fromDate:
          json['fromDate'] == null ? null : DateTime.parse(json['fromDate']),
      appInfo: json['appInfo'],
      featureFlags: json['featureFlags'] == null
          ? null
          : List<String>.from(json['featureFlags']),
      userInteractionRequired: json['userInteractionRequired'],
    );
  }
}

class MerchantStruct {
  int merchantId;
  String name;
  String? category;
  String? subcategory;
  String? locales;
  int version;
  String? logoLight;
  String? logoDark;

  MerchantStruct({
    required this.merchantId,
    required this.name,
    this.category,
    this.subcategory,
    this.locales,
    required this.version,
    this.logoLight,
    this.logoDark,
  });

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'locales': locales,
      'version': version,
      'logoLight': logoLight,
      'logoDark': logoDark,
    };
  }

  factory MerchantStruct.fromJson(Map<String, dynamic> json) {
    return MerchantStruct(
      merchantId: json['merchantId'],
      name: json['name'],
      category: json['category'],
      subcategory: json['subcategory'],
      locales: json['locales'],
      version: json['version'],
      logoLight: json['logoLight'],
      logoDark: json['logoDark'],
    );
  }
}

// MARK: - ScrapeStatus
// MARK: ScrapeRequest
// MARK: - Receipt
class ReceiptFeeStruct {
  String? price;
  String? name;

  ReceiptFeeStruct({
    this.price,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'name': name,
    };
  }

  factory ReceiptFeeStruct.fromJson(Map<String, dynamic> json) {
    return ReceiptFeeStruct(
      price: json['price'],
      name: json['name'],
    );
  }
}

class ReceiptAddressStruct {
  String? name;
  String? address1;
  String? address2;
  String? city;
  String? state;
  String? zip;

  ReceiptAddressStruct({
    this.name,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.zip,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address1': address1,
      'address2': address2,
      'city': city,
      'state': state,
      'zip': zip,
    };
  }

  factory ReceiptAddressStruct.fromJson(Map<String, dynamic> json) {
    return ReceiptAddressStruct(
      name: json['name'],
      address1: json['address1'],
      address2: json['address2'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
    );
  }
}

class ReceiptItemStruct {
  String? titleOriginal;
  String? title;
  List<String>? titleOther;
  List<String>? titleAuthors;
  String? quantity;
  String? weight;
  String? asin;
  String? imageUrl;
  String? productUrl;
  String? condition;
  String? soldBy;
  String? deliveryStatus;
  String? itemIndex;
  String? itemId;
  String? upc;
  String? brand;
  String? category;
  String? manufacturer;
  String? originalUnitPrice;
  String? unitPrice;
  String? totalPrice;
  String? notAvailable;
  String? substitution;
  String? substitutionPrice;
  String? color;
  String? size;
  String? type;
  String? trackingId;

  ReceiptItemStruct({
    this.titleOriginal,
    this.title,
    this.titleOther,
    this.titleAuthors,
    this.quantity,
    this.weight,
    this.asin,
    this.imageUrl,
    this.productUrl,
    this.condition,
    this.soldBy,
    this.deliveryStatus,
    this.itemIndex,
    this.itemId,
    this.upc,
    this.brand,
    this.category,
    this.manufacturer,
    this.originalUnitPrice,
    this.unitPrice,
    this.totalPrice,
    this.notAvailable,
    this.substitution,
    this.substitutionPrice,
    this.color,
    this.size,
    this.type,
    this.trackingId,
  });

  Map<String, dynamic> toJson() {
    return {
      'titleOriginal': titleOriginal,
      'title': title,
      'titleOther': titleOther,
      'titleAuthors': titleAuthors,
      'quantity': quantity,
      'weight': weight,
      'asin': asin,
      'imageUrl': imageUrl,
      'productUrl': productUrl,
      'condition': condition,
      'soldBy': soldBy,
      'deliveryStatus': deliveryStatus,
      'itemIndex': itemIndex,
      'itemId': itemId,
      'upc': upc,
      'brand': brand,
      'category': category,
      'manufacturer': manufacturer,
      'originalUnitPrice': originalUnitPrice,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notAvailable': notAvailable,
      'substitution': substitution,
      'substitutionPrice': substitutionPrice,
      'color': color,
      'size': size,
      'type': type,
      'trackingId': trackingId,
    };
  }

  factory ReceiptItemStruct.fromJson(Map<String, dynamic> json) {
    return ReceiptItemStruct(
      titleOriginal: json['titleOriginal'],
      title: json['title'],
      titleOther: json['titleOther'] == null
          ? null
          : List<String>.from(json['titleOther']),
      titleAuthors: json['titleAuthors'] == null
          ? null
          : List<String>.from(json['titleAuthors']),
      quantity: json['quantity'],
      weight: json['weight'],
      asin: json['asin'],
      imageUrl: json['imageUrl'],
      productUrl: json['productUrl'],
      condition: json['condition'],
      soldBy: json['soldBy'],
      deliveryStatus: json['deliveryStatus'],
      itemIndex: json['itemIndex'],
      itemId: json['itemId'],
      upc: json['upc'],
      brand: json['brand'],
      category: json['category'],
      manufacturer: json['manufacturer'],
      originalUnitPrice: json['originalUnitPrice'],
      unitPrice: json['unitPrice'],
      totalPrice: json['totalPrice'],
      notAvailable: json['notAvailable'],
      substitution: json['substitution'],
      substitutionPrice: json['substitutionPrice'],
      color: json['color'],
      size: json['size'],
      type: json['type'],
      trackingId: json['trackingId'],
    );
  }
}

class ReceiptStruct {
  int? roverMerchantId;
  String? roverUserId;
  String? roverAccountId;
  String? roverSessionUUID;
  String? transportId;
  String? emailProviderId;
  String? duplicationId;
  String? receiptId;
  String? emailId;
  String? receiptDomain;
  String? receiptFormat;
  String? deviceLocale;
  String? deviceTimezone;
  String? error;
  String? validationError;
  String? storeName;
  String? contentStoreName;
  String? serviceGroup;
  String? collectedDate;
  String? purchasedDate;
  String? continuationDate;
  String? membershipInfo;
  String? orderUrl;
  String? additionalOrderUrl;
  List<ReceiptFeeStruct>? fees;
  String? tax;
  String? total;
  String? totalWithoutTax;
  String? deliveryCharge;
  String? discounts;
  String? giftCards;
  String? tip;
  String? currency;
  String? paymentMethod;
  String? paymentChannel;
  ReceiptAddressStruct? shippingAddress;
  ReceiptAddressStruct? merchantAddress;
  ReceiptAddressStruct? billingAddress;
  List<ReceiptItemStruct> items;
  String? sourceData;
  String? clientInfo;
  String? auxData;
  String? merchantLocalPurchaseDate;
  String? emlOriginatingDate;
  String? emlOriginatingDateMerchantLocal;
  List<String>? emlSubjectKeywords;
  String? cancelled;
  String? preorder;
  String? returned;
  String? trackingId;

  ReceiptStruct({
    this.roverMerchantId,
    this.roverUserId,
    this.roverAccountId,
    this.roverSessionUUID,
    this.transportId,
    this.emailProviderId,
    this.duplicationId,
    this.receiptId,
    this.emailId,
    this.receiptDomain,
    this.receiptFormat,
    this.deviceLocale,
    this.deviceTimezone,
    this.error,
    this.validationError,
    this.storeName,
    this.contentStoreName,
    this.serviceGroup,
    this.collectedDate,
    this.purchasedDate,
    this.continuationDate,
    this.membershipInfo,
    this.orderUrl,
    this.additionalOrderUrl,
    this.fees,
    this.tax,
    this.total,
    this.totalWithoutTax,
    this.deliveryCharge,
    this.discounts,
    this.giftCards,
    this.tip,
    this.currency,
    this.paymentMethod,
    this.paymentChannel,
    this.shippingAddress,
    this.merchantAddress,
    this.billingAddress,
    required this.items,
    this.sourceData,
    this.clientInfo,
    this.auxData,
    this.merchantLocalPurchaseDate,
    this.emlOriginatingDate,
    this.emlOriginatingDateMerchantLocal,
    this.emlSubjectKeywords,
    this.cancelled,
    this.preorder,
    this.returned,
    this.trackingId,
  });

  Map<String, dynamic> toJson() {
    return {
      'roverMerchantId': roverMerchantId,
      'roverUserId': roverUserId,
      'roverAccountId': roverAccountId,
      'roverSessionUUID': roverSessionUUID,
      'transportId': transportId,
      'emailProviderId': emailProviderId,
      'duplicationId': duplicationId,
      'receiptId': receiptId,
      'emailId': emailId,
      'receiptDomain': receiptDomain,
      'receiptFormat': receiptFormat,
      'deviceLocale': deviceLocale,
      'deviceTimezone': deviceTimezone,
      'error': error,
      'validationError': validationError,
      'storeName': storeName,
      'contentStoreName': contentStoreName,
      'serviceGroup': serviceGroup,
      'collectedDate': collectedDate,
      'purchasedDate': purchasedDate,
      'continuationDate': continuationDate,
      'membershipInfo': membershipInfo,
      'orderUrl': orderUrl,
      'additionalOrderUrl': additionalOrderUrl,
      'fees': fees,
      'tax': tax,
      'total': total,
      'totalWithoutTax': totalWithoutTax,
      'deliveryCharge': deliveryCharge,
      'discounts': discounts,
      'giftCards': giftCards,
      'tip': tip,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentChannel': paymentChannel,
      'shippingAddress': shippingAddress,
      'merchantAddress': merchantAddress,
      'billingAddress': billingAddress,
      'items': items,
      'sourceData': sourceData,
      'clientInfo': clientInfo,
      'auxData': auxData,
      'merchantLocalPurchaseDate': merchantLocalPurchaseDate,
      'emlOriginatingDate': emlOriginatingDate,
      'emlOriginatingDateMerchantLocal': emlOriginatingDateMerchantLocal,
      'emlSubjectKeywords': emlSubjectKeywords,
      'cancelled': cancelled,
      'preorder': preorder,
      'returned': returned,
      'trackingId': trackingId,
    };
  }

  factory ReceiptStruct.fromJson(Map<String, dynamic> json) {
    return ReceiptStruct(
      roverMerchantId: json['roverMerchantId'],
      roverUserId: json['roverUserId'],
      roverAccountId: json['roverAccountId'],
      roverSessionUUID: json['roverSessionUUID'],
      transportId: json['transportId'],
      emailProviderId: json['emailProviderId'],
      duplicationId: json['duplicationId'],
      receiptId: json['receiptId'],
      emailId: json['emailId'],
      receiptDomain: json['receiptDomain'],
      receiptFormat: json['receiptFormat'],
      deviceLocale: json['deviceLocale'],
      deviceTimezone: json['deviceTimezone'],
      error: json['error'],
      validationError: json['validationError'],
      storeName: json['storeName'],
      contentStoreName: json['contentStoreName'],
      serviceGroup: json['serviceGroup'],
      collectedDate: json['collectedDate'],
      purchasedDate: json['purchasedDate'],
      continuationDate: json['continuationDate'],
      membershipInfo: json['membershipInfo'],
      orderUrl: json['orderUrl'],
      additionalOrderUrl: json['additionalOrderUrl'],
      fees: json['fees'] == null
          ? null
          : (json['fees'] as List<dynamic>)
              .map((v) => ReceiptFeeStruct.fromJson(v))
              .toList(),
      tax: json['tax'],
      total: json['total'],
      totalWithoutTax: json['totalWithoutTax'],
      deliveryCharge: json['deliveryCharge'],
      discounts: json['discounts'],
      giftCards: json['giftCards'],
      tip: json['tip'],
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      paymentChannel: json['paymentChannel'],
      shippingAddress: json['shippingAddress'] == null
          ? null
          : ReceiptAddressStruct.fromJson(json['shippingAddress']),
      merchantAddress: json['merchantAddress'] == null
          ? null
          : ReceiptAddressStruct.fromJson(json['merchantAddress']),
      billingAddress: json['billingAddress'] == null
          ? null
          : ReceiptAddressStruct.fromJson(json['billingAddress']),
      items: (json['items'] as List<dynamic>)
          .map((v) => ReceiptItemStruct.fromJson(v))
          .toList(),
      sourceData: json['sourceData'],
      clientInfo: json['clientInfo'],
      auxData: json['auxData'],
      merchantLocalPurchaseDate: json['merchantLocalPurchaseDate'],
      emlOriginatingDate: json['emlOriginatingDate'],
      emlOriginatingDateMerchantLocal: json['emlOriginatingDateMerchantLocal'],
      emlSubjectKeywords: json['emlSubjectKeywords'] == null
          ? null
          : List<String>.from(json['emlSubjectKeywords']),
      cancelled: json['cancelled'],
      preorder: json['preorder'],
      returned: json['returned'],
      trackingId: json['trackingId'],
    );
  }
}

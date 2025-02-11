import 'package:rover_flutter/rover_flutter.dart';
import 'package:uuid/uuid.dart';

class RoverDelegate {
  String uuid = Uuid().v4();

  void roverDidInit(String sessionUUID, dynamic scrapeRequest,
      void Function(dynamic, String?) callback) {
    // debugPrint("roverDidInit");
    callback(scrapeRequest, null);
  }

  void roverAccountDidLogin(
      String sessionUUID,
      String oldAccount,
      String newAccount,
      String password,
      String cookiesBase64,
      void Function(String?, String?) callback) {
    // debugPrint("roverAccountDidLogin: $newAccount");
    callback(null, null);
  }

  void roverHasStatus(
      String sessionUUID,
      double progress,
      double stepProgress,
      int currentStep,
      int maxSteps,
      String merchantVersion,
      List<String> tagLog,
      String userTag) {
    // debugPrint("roverHasStatus: ${progress * 100} $userTag");
  }

  void roverDidCollect(String sessionUUID, List<ReceiptStruct> receipts) {
    // debugPrint("roverDidCollect: ${receipts.length} receipts");
  }

  void roverDidFinish(String sessionUUID, String? error, String? userError,
      String? verboseError) {
    // debugPrint("roverDidFinish: $error");
  }
}

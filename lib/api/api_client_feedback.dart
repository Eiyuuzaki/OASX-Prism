part of 'api_client.dart';

extension ApiClientFeedbackX on ApiClient {
  void showDialog(String title, String content) {
    AppInfoBar.show(title, message: content);
  }

  void showNetErrSnackBar() {
    AppInfoBar.show(
      I18n.networkError.tr,
      message: I18n.networkConnectTimeout.tr,
      duration: const Duration(seconds: 5),
      );
  }

  void showNetErrCodeSnackBar(String msg, int code) {
    AppInfoBar.show(
      I18n.networkError.tr,
      message: '${I18n.networkErrorCode.tr}: $code | $msg',
      duration: const Duration(seconds: 5),
      );
  }
}

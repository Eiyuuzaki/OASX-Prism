import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';

class NotifyTest extends StatefulWidget {
  const NotifyTest({Key? key}) : super(key: key);

  @override
  NotifyTestState createState() => NotifyTestState();
}

class NotifyTestState extends State<NotifyTest> {
  String testConfig = 'provider:';
  String testTitle = 'Title';
  String testContent = 'Content';

  @override
  Widget build(BuildContext context) {
    return <Widget>[
      Text(I18n.notifyTest.tr,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium),
      _config(),
      _title(),
      _content(),
      const SizedBox(
        height: 20,
      ),
      _send(),
    ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(all: 10)
        .card(margin: const EdgeInsets.all(10))
        .constrained(maxWidth: 300, width: 300);
  }

  Widget _config() {
    return AppTextField(
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: null,
      initialValue: testConfig,
      onChanged: (value) {
          setState(() {
            testConfig = value;
          });
        },
      labelText: I18n.notifyTestConfig.tr,
      helperText: I18n.notifyTestHelp.tr,
    ).constrained(width: 300);
  }

  Widget _title() {
    return AppTextField(
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: null,
      initialValue: testTitle,
      onChanged: (value) {
          setState(() {
            testTitle = value;
          });
        },
      labelText: I18n.notifyTestTitle.tr,
    ).constrained(width: 300);
  }

  Widget _content() {
    return AppTextField(
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: null,
      initialValue: testContent,
      onChanged: (value) {
          setState(() {
            testContent = value;
          });
        },
      labelText: I18n.notifyTestContent.tr,
    ).constrained(width: 300);
  }

  Widget _send() {
    return MaterialButton(
      color: Theme.of(context).canvasColor,
      onPressed: () {
        ApiClient().notifyTest(testConfig, testTitle, testContent);
      },
      child: Text(I18n.notifyTestSend.tr),
    ).constrained(width: 300);
  }
}

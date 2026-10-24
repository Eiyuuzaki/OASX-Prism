import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/modules/args/index.dart';
import 'config_transfer_dialog.dart';
import 'package:oasx/ui/ui.dart';

enum _AddConfigAction { importJson }

Future<String?> showAddConfigDialog(
  BuildContext context, {
  VoidCallback? onSubmitting,
  VoidCallback? onSubmitDone,
}) async {
  String newName = await ApiClient().getNewConfigName();
  final fetchedConfigAll = await ApiClient().getConfigAll();
  final configAll = fetchedConfigAll.isEmpty
      ? <String>['template']
      : fetchedConfigAll;
  final defaultTemplate = configAll.contains('template')
      ? 'template'
      : (configAll.isNotEmpty ? configAll.first : 'template');
  final selectedTemplate = defaultTemplate.obs;
  final isSubmitting = false.obs;
  if (!context.mounted) {
    return null;
  }

  final result = await showDialog<Object>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(I18n.configAdd.tr),
        content: Obx(() {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (MediaQuery.sizeOf(dialogContext).height * 0.45)
                  .clamp(220.0, 420.0)
                  .toDouble(),
            ),
            child: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(I18n.newName.tr),
                    AppTextField(
                      initialValue: newName,
                      enabled: !isSubmitting.value,
                      onChanged: (value) {
                        newName = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(I18n.configCopyFromExist.tr),
                    AppDropdown<String>(
                      value: selectedTemplate.value,
                      maxWidth: double.infinity,
                      enabled: !isSubmitting.value,
                      items: configAll
                          .map((e) => AppDropdownItem(value: e, label: e))
                          .toList(),
                      onChanged: (value) {
                        selectedTemplate.value = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: isSubmitting.value
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop(_AddConfigAction.importJson);
                            },
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(I18n.configJsonImport.tr),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        actions: [
          AppButton(
  label: I18n.cancel.tr,
  variant: AppButtonVariant.text,
  onPressed: () {
              if (isSubmitting.value) return;
              Navigator.of(dialogContext).pop();
            },
),
          Obx(() {
            return AppButton(
              label: I18n.confirm.tr,
              variant: AppButtonVariant.primary,
              loading: isSubmitting.value,
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      onSubmitting?.call();
                      try {
                        final normalizedName = newName.trim();
                        final navList = await ApiClient().configCopy(
                          normalizedName,
                          selectedTemplate.value,
                        );
                        final scripts = navList.where((e) => e != 'Home');
                        await Get.find<ScriptService>().syncScriptsAndConnect(
                          scripts: scripts,
                          configName: normalizedName,
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(normalizedName);
                        }
                      } finally {
                        isSubmitting.value = false;
                        onSubmitDone?.call();
                      }
                    },
            );
          }),
        ],
      );
    },
  );
  if (result != _AddConfigAction.importJson) return result as String?;
  if (!context.mounted) return null;
  final imported = await ConfigTransferDialogs.importJson(
    context,
    initialName: newName,
    existingNames: configAll,
    guard: () =>
        Get.isRegistered<ArgsController>() &&
            Get.find<ArgsController>().hasDraftChanges
        ? I18n.configJsonUnsaved.tr
        : null,
  );
  if (imported == null) return null;
  onSubmitting?.call();
  try {
    final service = Get.find<ScriptService>();
    await service.syncScriptsAndConnect(
      scripts: {...service.scriptOrderList, imported.configName},
      configName: imported.configName,
    );
    if (context.mounted) {
      AppInfoBar.show(
        I18n.configJsonImported.tr,
        message: imported.warnings.join('\n'),
        severity: AppInfoBarSeverity.success,
      );
    }
  } finally {
    onSubmitDone?.call();
  }
  return imported.configName;
}

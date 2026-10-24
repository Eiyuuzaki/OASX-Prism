part of 'log_widget.dart';

class TopLogPanel extends StatelessWidget {
  const TopLogPanel({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.bottomChild,
  });

  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? bottomChild;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (enableAutoScroll ?? true) _autoScrollButton(),
              if (enableCopy ?? true) _copyButton(),
              if (enableClear ?? true) _deleteButton(),
              if (enableCollapse ?? true) _collapseButton(),
            ],
          ).paddingAll(8).constrained(height: 48),
          if (bottomChild != null) ...[
            const AppDivider(),
            bottomChild!,
          ],
        ],
      ),
    );
  }

  Widget _copyButton() {
    return AppIconButton(
      icon: Icons.content_copy_rounded,
      iconSize: 18,
      onPressed: () => controller.copyLogs(),
    );
  }

  Widget _autoScrollButton() {
    return Obx(
      () => AppIconButton(
        icon: controller.autoScroll.value ? Icons.flash_on : Icons.flash_off,
        iconSize: 20,
        onPressed: controller.toggleAutoScroll,
      ),
    );
  }

  Widget _deleteButton() {
    return AppIconButton(
      icon: Icons.delete_outlined,
      iconSize: 20,
      onPressed: () => controller.clearLog(),
    );
  }

  Widget _collapseButton() {
    return Obx(
      () => AppIconButton(
        icon: controller.collapseLog.value
            ? Icons.expand_more
            : Icons.expand_less,
        iconSize: 20,
        onPressed: () => controller.toggleCollapse(),
      ),
    );
  }
}

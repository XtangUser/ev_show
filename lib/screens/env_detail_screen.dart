import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/environment_info.dart';
import '../services/tool_usage_registry.dart';

class EnvDetailScreen extends StatelessWidget {
  final EnvironmentInfo info;

  const EnvDetailScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final usage = ToolUsageRegistry.get(info.id);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: info.categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(info.icon, size: 18, color: info.categoryColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  info.categoryLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: info.categoryColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 安装状态标签
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatusBadge(info: info),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 基本信息卡片 ──
            _InfoCard(info: info, theme: theme, cs: cs),
            const SizedBox(height: 16),

            // ── 未安装时：安装建议 ──
            if (info.status != ScanStatus.found && usage != null) ...[
              _InstallHintCard(usage: usage, theme: theme, cs: cs),
              const SizedBox(height: 16),
            ],

            // ── 已安装时：常用命令 ──
            if (info.status == ScanStatus.found && usage != null) ...[
              _CommandsCard(usage: usage, info: info, theme: theme, cs: cs),
              const SizedBox(height: 16),
            ],

            // ── 未安装且有命令列表 ──
            if (info.status != ScanStatus.found &&
                usage != null &&
                usage.commands.isNotEmpty) ...[
              _CommandsCard(
                usage: usage,
                info: info,
                theme: theme,
                cs: cs,
                isReference: true,
              ),
              const SizedBox(height: 16),
            ],

            // ── 额外信息（conda 环境列表、git 用户名等）──
            if (info.extra != null && info.extra!.isNotEmpty) ...[
              _ExtraInfoCard(info: info, theme: theme, cs: cs),
              const SizedBox(height: 16),
            ],

            // ── 官方文档链接 ──
            if (usage != null)
              _DocLinkCard(
                url: usage.officialUrl,
                name: info.name,
                theme: theme,
                cs: cs,
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 状态标签
// ══════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final EnvironmentInfo info;
  const _StatusBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    switch (info.status) {
      case ScanStatus.found:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 13,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              Text(
                '已安装${info.version != null ? "  v${info.version}" : ""}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case ScanStatus.notFound:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_circle_outline, size: 13, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                '未安装',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════
// 基本信息卡片
// ══════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final EnvironmentInfo info;
  final ThemeData theme;
  final ColorScheme cs;

  const _InfoCard({required this.info, required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '基本信息',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow('说明', info.description, theme, cs),
            if (info.version != null)
              _buildRow('版本号', info.version!, theme, cs, highlight: true),
            if (info.executablePath != null)
              _buildRow(
                '安装路径',
                info.executablePath!,
                theme,
                cs,
                copyable: true,
              ),
            if (info.scannedAt != null)
              _buildRow('扫描时间', _formatTime(info.scannedAt!), theme, cs),
            if (info.status == ScanStatus.error && info.errorMessage != null)
              _buildRow(
                '错误信息',
                info.errorMessage!,
                theme,
                cs,
                color: Colors.orange,
              ),

            // ── 多实例信息 ──
            if (info.instances != null && info.instances!.length > 1) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 16, color: cs.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '发现多个实例 (${info.instances!.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...info.instances!.map((instance) => _buildInstanceRow(instance, theme, cs)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstanceRow(ToolInstance instance, ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (instance.name != null) ...[
                Text(
                  instance.name!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  instance.version,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.folder_open, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: SelectableText(
                  instance.path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  Widget _buildRow(
    String label,
    String value,
    ThemeData theme,
    ColorScheme cs, {
    bool copyable = false,
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: highlight ? 'monospace' : null,
                fontWeight: highlight ? FontWeight.w700 : null,
                color:
                    color ??
                    (highlight
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.85)),
                fontSize: highlight ? 13 : 12,
              ),
            ),
          ),
          if (copyable)
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('已复制到剪贴板'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Tooltip(
                  message: '复制路径',
                  child: Icon(
                    Icons.copy_outlined,
                    size: 14,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 安装建议卡片
// ══════════════════════════════════════════════
class _InstallHintCard extends StatelessWidget {
  final ToolUsage usage;
  final ThemeData theme;
  final ColorScheme cs;

  const _InstallHintCard({
    required this.usage,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.download_outlined,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  '如何安装',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
              ),
              child: SelectableText(
                usage.installHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 常用命令卡片
// ══════════════════════════════════════════════
class _CommandsCard extends StatelessWidget {
  final ToolUsage usage;
  final EnvironmentInfo info;
  final ThemeData theme;
  final ColorScheme cs;
  final bool isReference; // true = 仅供参考（未安装时展示）

  const _CommandsCard({
    required this.usage,
    required this.info,
    required this.theme,
    required this.cs,
    this.isReference = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isReference
        ? cs.onSurface.withValues(alpha: 0.5)
        : info.categoryColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal_outlined, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  isReference ? '常用命令（供参考）' : '常用命令',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (isReference) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '未安装，仅供了解',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ...usage.commands.map(
              (cmd) => _CommandItem(
                item: cmd,
                accentColor: isReference
                    ? cs.onSurface.withValues(alpha: 0.3)
                    : info.categoryColor,
                theme: theme,
                cs: cs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 单条命令 ──────────────────────────────────
class _CommandItem extends StatefulWidget {
  final ToolUsageItem item;
  final Color accentColor;
  final ThemeData theme;
  final ColorScheme cs;

  const _CommandItem({
    required this.item,
    required this.accentColor,
    required this.theme,
    required this.cs,
  });

  @override
  State<_CommandItem> createState() => _CommandItemState();
}

class _CommandItemState extends State<_CommandItem> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.item.command));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签行
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.item.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 命令块
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Text(
                  '> ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: widget.accentColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    widget.item.command,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _copied ? '已复制！' : '复制命令',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: _copy,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _copied ? Icons.check : Icons.copy_outlined,
                          key: ValueKey(_copied),
                          size: 14,
                          color: _copied
                              ? Colors.green
                              : cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 命令说明
          if (widget.item.description != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                widget.item.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 额外信息卡片
// ══════════════════════════════════════════════
class _ExtraInfoCard extends StatelessWidget {
  final EnvironmentInfo info;
  final ThemeData theme;
  final ColorScheme cs;

  const _ExtraInfoCard({
    required this.info,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: 16,
                  color: info.categoryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '详细信息',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: info.categoryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...info.extra!.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        e.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        e.value,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 官方文档链接卡片
// ══════════════════════════════════════════════
class _DocLinkCard extends StatelessWidget {
  final String url;
  final String name;
  final ThemeData theme;
  final ColorScheme cs;

  const _DocLinkCard({
    required this.url,
    required this.name,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('官方文档链接已复制：$url'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.open_in_browser_outlined,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name 官方文档',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy_outlined,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

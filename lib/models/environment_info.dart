import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────
// 工具使用说明条目
// ──────────────────────────────────────────────────────────────

/// 单条使用命令示例
class ToolUsageItem {
  final String label; // 简短说明，如"检查版本"
  final String command; // 实际命令，如"python --version"
  final String? description; // 可选的详细说明

  const ToolUsageItem({
    required this.label,
    required this.command,
    this.description,
  });
}

/// 工具使用说明汇总
class ToolUsage {
  final String id;
  final String officialUrl; // 官方文档链接
  final String installHint; // 未安装时的安装建议
  final List<ToolUsageItem> commands; // 常用命令列表

  const ToolUsage({
    required this.id,
    required this.officialUrl,
    required this.installHint,
    required this.commands,
  });
}

/// 环境所属分类
enum EnvironmentCategory {
  language, // 编程语言
  packageManager, // 包管理器
  versionManager, // 版本管理工具
  versionControl, // 版本控制
  container, // 容器与虚拟化
  ide, // 编辑器与IDE
  database, // 数据库
  cloud, // 云工具
  buildTool, // 构建工具
  runtime, // 运行时
}

/// 扫描状态
enum ScanStatus {
  pending, // 等待扫描
  scanning, // 扫描中
  found, // 已找到
  notFound, // 未找到
  error, // 出错
}

/// 单个工具实例（用于支持多版本/多安装路径）
class ToolInstance {
  final String version;
  final String path;
  final String? name; // 实例名称，如服务名、虚拟环境名等
  final Map<String, String>? extra;

  const ToolInstance({
    required this.version,
    required this.path,
    this.name,
    this.extra,
  });
}

/// 单个环境信息
class EnvironmentInfo {
  final String id;
  final String name;
  final String description;
  final String hint; // 用户友好提示，如 "用于运行Python脚本"
  final EnvironmentCategory category;
  final IconData icon;
  final Color categoryColor;

  ScanStatus status;
  String? version;
  String? executablePath;
  String? errorMessage;
  Map<String, String>? extra; // 附加信息，如conda环境列表
  List<ToolInstance>? instances; // 发现的多个实例
  DateTime? scannedAt;

  EnvironmentInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.hint,
    required this.category,
    required this.icon,
    required this.categoryColor,
    this.status = ScanStatus.pending,
    this.version,
    this.executablePath,
    this.errorMessage,
    this.extra,
    this.instances,
    this.scannedAt,
  });

  /// 是否已安装
  bool get isInstalled => status == ScanStatus.found;

  /// 分类名称（中文）
  String get categoryLabel {
    switch (category) {
      case EnvironmentCategory.language:
        return '编程语言';
      case EnvironmentCategory.packageManager:
        return '包管理器';
      case EnvironmentCategory.versionManager:
        return '版本管理';
      case EnvironmentCategory.versionControl:
        return '版本控制';
      case EnvironmentCategory.container:
        return '容器 & 虚拟化';
      case EnvironmentCategory.ide:
        return '编辑器 & IDE';
      case EnvironmentCategory.database:
        return '数据库';
      case EnvironmentCategory.cloud:
        return '云工具';
      case EnvironmentCategory.buildTool:
        return '构建工具';
      case EnvironmentCategory.runtime:
        return '运行时 & 其他';
    }
  }

  EnvironmentInfo copyWith({
    ScanStatus? status,
    String? version,
    String? executablePath,
    String? errorMessage,
    Map<String, String>? extra,
    List<ToolInstance>? instances,
    DateTime? scannedAt,
  }) {
    return EnvironmentInfo(
      id: id,
      name: name,
      description: description,
      hint: hint,
      category: category,
      icon: icon,
      categoryColor: categoryColor,
      status: status ?? this.status,
      version: version ?? this.version,
      executablePath: executablePath ?? this.executablePath,
      errorMessage: errorMessage ?? this.errorMessage,
      extra: extra ?? this.extra,
      instances: instances ?? this.instances,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}

/// 分类元数据
class CategoryMeta {
  final EnvironmentCategory category;
  final String label;
  final Color color;
  final IconData icon;

  const CategoryMeta({
    required this.category,
    required this.label,
    required this.color,
    required this.icon,
  });
}

const kCategoryMeta = <EnvironmentCategory, CategoryMeta>{
  EnvironmentCategory.language: CategoryMeta(
    category: EnvironmentCategory.language,
    label: '编程语言',
    color: Color(0xFF3B82F6),
    icon: Icons.code,
  ),
  EnvironmentCategory.packageManager: CategoryMeta(
    category: EnvironmentCategory.packageManager,
    label: '包管理器',
    color: Color(0xFF8B5CF6),
    icon: Icons.inventory_2_outlined,
  ),
  EnvironmentCategory.versionManager: CategoryMeta(
    category: EnvironmentCategory.versionManager,
    label: '版本管理',
    color: Color(0xFFF59E0B),
    icon: Icons.layers_outlined,
  ),
  EnvironmentCategory.versionControl: CategoryMeta(
    category: EnvironmentCategory.versionControl,
    label: '版本控制',
    color: Color(0xFFEF4444),
    icon: Icons.history,
  ),
  EnvironmentCategory.container: CategoryMeta(
    category: EnvironmentCategory.container,
    label: '容器 & 虚拟化',
    color: Color(0xFF06B6D4),
    icon: Icons.widgets_outlined,
  ),
  EnvironmentCategory.ide: CategoryMeta(
    category: EnvironmentCategory.ide,
    label: '编辑器 & IDE',
    color: Color(0xFF10B981),
    icon: Icons.developer_mode,
  ),
  EnvironmentCategory.database: CategoryMeta(
    category: EnvironmentCategory.database,
    label: '数据库',
    color: Color(0xFFF97316),
    icon: Icons.storage,
  ),
  EnvironmentCategory.cloud: CategoryMeta(
    category: EnvironmentCategory.cloud,
    label: '云工具',
    color: Color(0xFF64748B),
    icon: Icons.cloud_outlined,
  ),
  EnvironmentCategory.buildTool: CategoryMeta(
    category: EnvironmentCategory.buildTool,
    label: '构建工具',
    color: Color(0xFFEC4899),
    icon: Icons.build_outlined,
  ),
  EnvironmentCategory.runtime: CategoryMeta(
    category: EnvironmentCategory.runtime,
    label: '运行时 & 其他',
    color: Color(0xFF84CC16),
    icon: Icons.settings_applications,
  ),
};

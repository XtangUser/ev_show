import 'dart:io';
import '../models/environment_info.dart';

/// 单条扫描命令定义
class ScanCommand {
  final String executable;
  final List<String> args;
  final bool useStderr; // java -version 等工具将版本写到 stderr
  final RegExp? versionPattern; // 从输出中提取版本号的正则

  const ScanCommand({
    required this.executable,
    required this.args,
    this.useStderr = false,
    this.versionPattern,
  });
}

/// 一个工具的扫描配置
class ScanDefinition {
  final String id;
  final List<ScanCommand> commands; // 按顺序尝试，第一个成功则停止
  final Future<ScanResult?> Function()? customScanFn; // 自定义扫描逻辑
  final Future<Map<String, String>?> Function()? extraInfoFn; // 额外信息采集

  const ScanDefinition({
    required this.id,
    required this.commands,
    this.customScanFn,
    this.extraInfoFn,
  });
}

/// 扫描结果
class ScanResult {
  final bool found;
  final String? version;
  final String? path;
  final String? error;
  final Map<String, String>? extra;
  final List<ToolInstance>? instances;

  const ScanResult({
    required this.found,
    this.version,
    this.path,
    this.error,
    this.extra,
    this.instances,
  });
}

/// 环境扫描服务
class ScannerService {
  // ──────────────────────────────────────────────
  // 版本提取通用正则
  // ──────────────────────────────────────────────
  static final _semver = RegExp(r'(\d+\.\d+[\.\d+]*)');

  static String? _extractVersion(String output, RegExp? custom) {
    final pattern = custom ?? _semver;
    final match = pattern.firstMatch(output);
    return match?.group(1);
  }

  // ──────────────────────────────────────────────
  // 工具定义表
  // ──────────────────────────────────────────────
  static final Map<String, ScanDefinition> _definitions = {
    // ── 编程语言 ───────────────────────────────
    'python': ScanDefinition(
      id: 'python',
      commands: [
        ScanCommand(executable: 'python', args: ['--version']),
        ScanCommand(executable: 'python3', args: ['--version']),
      ],
      extraInfoFn: () => _getPythonExtra(),
    ),

    'java': ScanDefinition(
      id: 'java',
      commands: [
        ScanCommand(
          executable: 'java',
          args: ['-version'],
          useStderr: true,
          versionPattern: RegExp(r'version "([^"]+)"'),
        ),
      ],
    ),

    'nodejs': ScanDefinition(
      id: 'nodejs',
      commands: [
        ScanCommand(
          executable: 'node',
          args: ['--version'],
          versionPattern: RegExp(r'v(\d+\.\d+\.\d+)'),
        ),
      ],
    ),

    'go': ScanDefinition(
      id: 'go',
      commands: [
        ScanCommand(
          executable: 'go',
          args: ['version'],
          versionPattern: RegExp(r'go(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'rust': ScanDefinition(
      id: 'rust',
      commands: [
        ScanCommand(
          executable: 'rustc',
          args: ['--version'],
          versionPattern: RegExp(r'rustc (\d+\.\d+\.\d+)'),
        ),
      ],
    ),

    'ruby': ScanDefinition(
      id: 'ruby',
      commands: [
        ScanCommand(executable: 'ruby', args: ['--version']),
      ],
    ),

    'php': ScanDefinition(
      id: 'php',
      commands: [
        ScanCommand(executable: 'php', args: ['--version']),
      ],
    ),

    'dotnet': ScanDefinition(
      id: 'dotnet',
      commands: [
        ScanCommand(executable: 'dotnet', args: ['--version']),
      ],
    ),

    'dart': ScanDefinition(
      id: 'dart',
      commands: [
        ScanCommand(executable: 'dart', args: ['--version'], useStderr: true),
      ],
    ),

    'kotlin': ScanDefinition(
      id: 'kotlin',
      commands: [
        ScanCommand(executable: 'kotlin', args: ['-version'], useStderr: true),
        ScanCommand(executable: 'kotlinc', args: ['-version'], useStderr: true),
      ],
    ),

    'scala': ScanDefinition(
      id: 'scala',
      commands: [
        ScanCommand(executable: 'scala', args: ['-version'], useStderr: true),
      ],
    ),

    'perl': ScanDefinition(
      id: 'perl',
      commands: [
        ScanCommand(executable: 'perl', args: ['--version']),
      ],
    ),

    'lua': ScanDefinition(
      id: 'lua',
      commands: [
        ScanCommand(executable: 'lua', args: ['-v'], useStderr: true),
        ScanCommand(executable: 'lua5.4', args: ['-v'], useStderr: true),
      ],
    ),

    'r_lang': ScanDefinition(
      id: 'r_lang',
      commands: [
        ScanCommand(
          executable: 'Rscript',
          args: ['--version'],
          useStderr: true,
        ),
      ],
    ),

    'swift': ScanDefinition(
      id: 'swift',
      commands: [
        ScanCommand(executable: 'swift', args: ['--version']),
      ],
    ),

    // ── 包管理器 ───────────────────────────────
    'pip': ScanDefinition(
      id: 'pip',
      commands: [
        ScanCommand(executable: 'pip', args: ['--version']),
        ScanCommand(executable: 'pip3', args: ['--version']),
      ],
    ),

    'conda': ScanDefinition(
      id: 'conda',
      commands: [
        ScanCommand(executable: 'conda', args: ['--version']),
      ],
      extraInfoFn: () => _getCondaEnvs(),
    ),

    'npm': ScanDefinition(
      id: 'npm',
      commands: [
        ScanCommand(executable: 'npm', args: ['--version']),
      ],
    ),

    'yarn': ScanDefinition(
      id: 'yarn',
      commands: [
        ScanCommand(executable: 'yarn', args: ['--version']),
      ],
    ),

    'pnpm': ScanDefinition(
      id: 'pnpm',
      commands: [
        ScanCommand(executable: 'pnpm', args: ['--version']),
      ],
    ),

    'bun': ScanDefinition(
      id: 'bun',
      commands: [
        ScanCommand(executable: 'bun', args: ['--version']),
      ],
    ),

    'cargo': ScanDefinition(
      id: 'cargo',
      commands: [
        ScanCommand(
          executable: 'cargo',
          args: ['--version'],
          versionPattern: RegExp(r'cargo (\d+\.\d+\.\d+)'),
        ),
      ],
    ),

    'maven': ScanDefinition(
      id: 'maven',
      commands: [
        ScanCommand(
          executable: 'mvn',
          args: ['--version'],
          versionPattern: RegExp(r'Apache Maven (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'gradle': ScanDefinition(
      id: 'gradle',
      commands: [
        ScanCommand(
          executable: 'gradle',
          args: ['--version'],
          versionPattern: RegExp(r'Gradle (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'composer': ScanDefinition(
      id: 'composer',
      commands: [
        ScanCommand(
          executable: 'composer',
          args: ['--version'],
          versionPattern: RegExp(r'Composer version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'gem': ScanDefinition(
      id: 'gem',
      commands: [
        ScanCommand(executable: 'gem', args: ['--version']),
      ],
    ),

    'poetry': ScanDefinition(
      id: 'poetry',
      commands: [
        ScanCommand(
          executable: 'poetry',
          args: ['--version'],
          versionPattern: RegExp(r'Poetry \(version (\d+\.\d+[\.\d]*)\)'),
        ),
      ],
    ),

    'pipenv': ScanDefinition(
      id: 'pipenv',
      commands: [
        ScanCommand(
          executable: 'pipenv',
          args: ['--version'],
          versionPattern: RegExp(r'pipenv, version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'uv': ScanDefinition(
      id: 'uv',
      commands: [
        ScanCommand(
          executable: 'uv',
          args: ['--version'],
          versionPattern: RegExp(r'uv (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    // ── 版本管理 ───────────────────────────────
    'pyenv': ScanDefinition(
      id: 'pyenv',
      commands: [
        ScanCommand(
          executable: 'pyenv',
          args: ['--version'],
          versionPattern: RegExp(r'pyenv (\d+\.\d+[\.\d]*)'),
        ),
      ],
      extraInfoFn: () => _getPyenvVersions(),
    ),

    'nvm': ScanDefinition(
      id: 'nvm',
      commands: [
        ScanCommand(executable: 'nvm', args: ['--version']),
      ],
      extraInfoFn: () => _getNvmVersions(),
    ),

    'sdkman': ScanDefinition(
      id: 'sdkman',
      commands: [
        ScanCommand(executable: 'sdk', args: ['version']),
      ],
    ),

    // ── 版本控制 ───────────────────────────────
    'git': ScanDefinition(
      id: 'git',
      commands: [
        ScanCommand(
          executable: 'git',
          args: ['--version'],
          versionPattern: RegExp(r'git version (\d+\.\d+[\.\d]*)'),
        ),
      ],
      extraInfoFn: () => _getGitConfig(),
    ),

    'svn': ScanDefinition(
      id: 'svn',
      commands: [
        ScanCommand(
          executable: 'svn',
          args: ['--version'],
          versionPattern: RegExp(r'version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'gh': ScanDefinition(
      id: 'gh',
      commands: [
        ScanCommand(
          executable: 'gh',
          args: ['--version'],
          versionPattern: RegExp(r'gh version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    // ── 容器 & 虚拟化 ─────────────────────────
    'docker': ScanDefinition(
      id: 'docker',
      commands: [
        ScanCommand(
          executable: 'docker',
          args: ['--version'],
          versionPattern: RegExp(r'Docker version (\d+\.\d+[\.\d]*)'),
        ),
      ],
      extraInfoFn: () => _getDockerInfo(),
    ),

    'kubectl': ScanDefinition(
      id: 'kubectl',
      commands: [
        ScanCommand(
          executable: 'kubectl',
          args: ['version', '--client', '--short'],
          versionPattern: RegExp(r'v(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'podman': ScanDefinition(
      id: 'podman',
      commands: [
        ScanCommand(
          executable: 'podman',
          args: ['--version'],
          versionPattern: RegExp(r'podman version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'helm': ScanDefinition(
      id: 'helm',
      commands: [
        ScanCommand(
          executable: 'helm',
          args: ['version', '--short'],
          versionPattern: RegExp(r'v(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'vagrant': ScanDefinition(
      id: 'vagrant',
      commands: [
        ScanCommand(
          executable: 'vagrant',
          args: ['--version'],
          versionPattern: RegExp(r'Vagrant (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'minikube': ScanDefinition(
      id: 'minikube',
      commands: [
        ScanCommand(
          executable: 'minikube',
          args: ['version'],
          versionPattern: RegExp(r'minikube version: v(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    // ── 编辑器 & IDE ──────────────────────────
    'vscode': ScanDefinition(
      id: 'vscode',
      commands: [
        ScanCommand(executable: 'code', args: ['--version']),
      ],
    ),

    'vscode_insiders': ScanDefinition(
      id: 'vscode_insiders',
      commands: [
        ScanCommand(executable: 'code-insiders', args: ['--version']),
      ],
    ),

    // ── 数据库 ────────────────────────────────
    'mysql': ScanDefinition(
      id: 'mysql',
      commands: [
        ScanCommand(
          executable: 'mysql',
          args: ['--version'],
          versionPattern: RegExp(r'(\d+\.\d+[\.\d]*)'),
        ),
      ],
      customScanFn: () => _getMysqlScan(),
    ),

    'psql': ScanDefinition(
      id: 'psql',
      commands: [
        ScanCommand(
          executable: 'psql',
          args: ['--version'],
          versionPattern: RegExp(r'(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'mongod': ScanDefinition(
      id: 'mongod',
      commands: [
        ScanCommand(
          executable: 'mongod',
          args: ['--version'],
          versionPattern: RegExp(r'db version v(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'redis': ScanDefinition(
      id: 'redis',
      commands: [
        ScanCommand(
          executable: 'redis-server',
          args: ['--version'],
          versionPattern: RegExp(r'v=(\d+\.\d+[\.\d]*)'),
        ),
      ],
      customScanFn: () => _getRedisScan(),
    ),

    'sqlite': ScanDefinition(
      id: 'sqlite',
      commands: [
        ScanCommand(executable: 'sqlite3', args: ['--version']),
      ],
    ),

    // ── 云工具 ────────────────────────────────
    'awscli': ScanDefinition(
      id: 'awscli',
      commands: [
        ScanCommand(
          executable: 'aws',
          args: ['--version'],
          useStderr: true,
          versionPattern: RegExp(r'aws-cli/(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'azcli': ScanDefinition(
      id: 'azcli',
      commands: [
        ScanCommand(
          executable: 'az',
          args: ['--version'],
          versionPattern: RegExp(r'azure-cli\s+(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'gcloud': ScanDefinition(
      id: 'gcloud',
      commands: [
        ScanCommand(
          executable: 'gcloud',
          args: ['--version'],
          versionPattern: RegExp(r'Google Cloud SDK (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'terraform': ScanDefinition(
      id: 'terraform',
      commands: [
        ScanCommand(
          executable: 'terraform',
          args: ['--version'],
          versionPattern: RegExp(r'Terraform v(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'heroku': ScanDefinition(
      id: 'heroku',
      commands: [
        ScanCommand(
          executable: 'heroku',
          args: ['--version'],
          versionPattern: RegExp(r'heroku/(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    // ── 构建工具 ──────────────────────────────
    'make': ScanDefinition(
      id: 'make',
      commands: [
        ScanCommand(
          executable: 'make',
          args: ['--version'],
          versionPattern: RegExp(r'GNU Make (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'cmake': ScanDefinition(
      id: 'cmake',
      commands: [
        ScanCommand(
          executable: 'cmake',
          args: ['--version'],
          versionPattern: RegExp(r'cmake version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'ninja': ScanDefinition(
      id: 'ninja',
      commands: [
        ScanCommand(executable: 'ninja', args: ['--version']),
      ],
    ),

    'ant': ScanDefinition(
      id: 'ant',
      commands: [
        ScanCommand(
          executable: 'ant',
          args: ['-version'],
          versionPattern: RegExp(r'Apache Ant.* version (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    // ── 运行时 & 其他 ─────────────────────────
    'flutter': ScanDefinition(
      id: 'flutter',
      commands: [
        ScanCommand(
          executable: 'flutter',
          args: ['--version'],
          versionPattern: RegExp(r'Flutter (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'android_adb': ScanDefinition(
      id: 'android_adb',
      commands: [
        ScanCommand(
          executable: 'adb',
          args: ['--version'],
          versionPattern: RegExp(r'Version (\d+\.\d+[\.\d-]*)'),
        ),
      ],
    ),

    'deno': ScanDefinition(
      id: 'deno',
      commands: [
        ScanCommand(
          executable: 'deno',
          args: ['--version'],
          versionPattern: RegExp(r'deno (\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'wsl': ScanDefinition(
      id: 'wsl',
      commands: [
        ScanCommand(
          executable: 'wsl',
          args: ['--version'],
          versionPattern: RegExp(r'(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),

    'nginx': ScanDefinition(
      id: 'nginx',
      commands: [
        ScanCommand(
          executable: 'nginx',
          args: ['-v'],
          useStderr: true,
          versionPattern: RegExp(r'nginx/(\d+\.\d+[\.\d]*)'),
        ),
      ],
    ),
  };

  // ──────────────────────────────────────────────
  // 运行单个扫描
  // ──────────────────────────────────────────────
  static Future<ScanResult> _runScan(ScanDefinition def) async {
    // 1. 尝试常规命令
    for (final cmd in def.commands) {
      try {
        final result = await Process.run(
          cmd.executable,
          cmd.args,
          runInShell: true,
        ).timeout(const Duration(seconds: 10));

        final rawOut = cmd.useStderr
            ? (result.stderr as String)
            : (result.stdout as String);
        final combined = '${result.stdout}${result.stderr}';

        if (result.exitCode != 0 && rawOut.trim().isEmpty) continue;

        final version = _extractVersion(
          rawOut.trim().isNotEmpty ? rawOut : combined,
          cmd.versionPattern,
        );

        // 查找可执行文件路径
        String? exePath;
        try {
          final whereResult = await Process.run('where', [
            cmd.executable,
          ], runInShell: true).timeout(const Duration(seconds: 5));
          if (whereResult.exitCode == 0) {
            exePath = (whereResult.stdout as String).split('\n').first.trim();
          }
        } catch (_) {}

        // 收集额外信息
        Map<String, String>? extra;
        if (def.extraInfoFn != null) {
          try {
            extra = await def.extraInfoFn!();
          } catch (_) {}
        }

        return ScanResult(
          found: true,
          version: version,
          path: exePath,
          extra: extra,
        );
      } catch (e) {
        // 当前命令失败，尝试下一个
        continue;
      }
    }

    // 2. 如果常规命令失败，尝试自定义扫描逻辑
    if (def.customScanFn != null) {
      try {
        final customRes = await def.customScanFn!();
        if (customRes != null && customRes.found) {
          return customRes;
        }
      } catch (_) {}
    }

    return const ScanResult(found: false);
  }

  // ──────────────────────────────────────────────
  // 公开 API：扫描一个工具
  // ──────────────────────────────────────────────
  static Future<ScanResult> scan(String id) async {
    final def = _definitions[id];
    if (def == null) {
      return const ScanResult(found: false, error: 'Unknown tool');
    }
    return _runScan(def);
  }

  /// 所有已配置的工具 ID 列表
  static List<String> get allIds => _definitions.keys.toList();

  // ──────────────────────────────────────────────
  // 额外信息采集函数
  // ──────────────────────────────────────────────

  static Future<Map<String, String>?> _getPythonExtra() async {
    try {
      // 检测是否在虚拟环境中（VIRTUAL_ENV 环境变量）
      final venv = Platform.environment['VIRTUAL_ENV'];
      if (venv != null && venv.isNotEmpty) {
        return {'当前虚拟环境': venv};
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, String>?> _getCondaEnvs() async {
    try {
      final result = await Process.run('conda', [
        'env',
        'list',
      ], runInShell: true).timeout(const Duration(seconds: 15));
      if (result.exitCode != 0) return null;

      final lines = (result.stdout as String)
          .split('\n')
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toList();

      final envs = <String>[];
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty && parts.first.isNotEmpty) {
          final name = parts.first == '*' && parts.length > 1
              ? '${parts[1]} (当前激活)'
              : parts.first;
          envs.add(name);
        }
      }

      if (envs.isEmpty) return null;
      return {'conda 环境': envs.join('、')};
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>?> _getPyenvVersions() async {
    try {
      final result = await Process.run('pyenv', [
        'versions',
      ], runInShell: true).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) return null;

      final versions = (result.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.trim().replaceFirst('* ', ''))
          .take(5)
          .join('、');

      return versions.isNotEmpty ? {'已管理的 Python 版本': versions} : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>?> _getNvmVersions() async {
    try {
      final result = await Process.run('nvm', [
        'list',
      ], runInShell: true).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) return null;

      final out = result.stdout as String;
      final versions = out
          .split('\n')
          .where((l) => RegExp(r'\d+\.\d+').hasMatch(l))
          .map((l) => l.trim())
          .take(5)
          .join('、');

      return versions.isNotEmpty ? {'已管理的 Node.js 版本': versions} : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>?> _getDockerInfo() async {
    try {
      // 检查 Docker 守护进程是否在运行
      final pingResult = await Process.run('docker', [
        'info',
        '--format',
        '{{.ServerVersion}}',
      ], runInShell: true).timeout(const Duration(seconds: 6));

      if (pingResult.exitCode != 0) {
        return {'守护进程状态': 'Docker Desktop 未运行（请先启动 Docker Desktop）'};
      }

      final extra = <String, String>{};

      // 服务端版本
      final serverVer = (pingResult.stdout as String).trim();
      if (serverVer.isNotEmpty) extra['服务端版本'] = serverVer;

      // 运行中的容器
      final psResult = await Process.run('docker', [
        'ps',
        '--format',
        '{{.Names}}',
      ], runInShell: true).timeout(const Duration(seconds: 6));
      if (psResult.exitCode == 0) {
        final names = (psResult.stdout as String)
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        extra['运行中容器'] = names.isEmpty
            ? '无'
            : '${names.length} 个：${names.take(4).join('、')}${names.length > 4 ? ' ...' : ''}';
      }

      // 全部容器数量
      final psAllResult = await Process.run('docker', [
        'ps',
        '-a',
        '-q',
      ], runInShell: true).timeout(const Duration(seconds: 6));
      if (psAllResult.exitCode == 0) {
        final total = (psAllResult.stdout as String)
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .length;
        extra['容器总数'] = '$total 个';
      }

      // 本地镜像数量
      final imagesResult = await Process.run('docker', [
        'images',
        '-q',
      ], runInShell: true).timeout(const Duration(seconds: 6));
      if (imagesResult.exitCode == 0) {
        final imgCount = (imagesResult.stdout as String)
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .length;
        extra['本地镜像数'] = '$imgCount 个';
      }

      // 磁盘使用（docker system df 精简）
      final dfResult = await Process.run('docker', [
        'system',
        'df',
        '--format',
        '{{.Type}}\t{{.TotalCount}}\t{{.Size}}',
      ], runInShell: true).timeout(const Duration(seconds: 8));
      if (dfResult.exitCode == 0) {
        final lines = (dfResult.stdout as String)
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          extra['磁盘占用'] = lines
              .map((l) {
                final parts = l.split('\t');
                if (parts.length >= 3) return '${parts[0]}：${parts[2]}';
                return l;
              })
              .join(' / ');
        }
      }

      return extra.isNotEmpty ? extra : null;
    } catch (_) {
      return {'守护进程状态': 'Docker Desktop 未运行或无响应'};
    }
  }

  static Future<Map<String, String>?> _getGitConfig() async {
    try {
      final nameResult = await Process.run('git', [
        'config',
        '--global',
        'user.name',
      ], runInShell: true);
      final emailResult = await Process.run('git', [
        'config',
        '--global',
        'user.email',
      ], runInShell: true);

      final extra = <String, String>{};
      final name = (nameResult.stdout as String).trim();
      final email = (emailResult.stdout as String).trim();

      if (name.isNotEmpty) extra['全局用户名'] = name;
      if (email.isNotEmpty) extra['全局邮箱'] = email;

      return extra.isNotEmpty ? extra : null;
    } catch (_) {
      return null;
    }
  }

  static Future<ScanResult?> _getMysqlScan() async {
    if (!Platform.isWindows) return null;

    try {
      // 1. 查找所有带有 MySQL 关键字的服务
      final result = await Process.run('sc.exe', ['query', 'state=', 'all'], runInShell: true)
          .timeout(const Duration(seconds: 10));

      if (result.exitCode != 0) return null;

      final out = result.stdout as String;
      final serviceNames = RegExp(r'SERVICE_NAME:\s+(MySQL\S*)', caseSensitive: false)
          .allMatches(out)
          .map((m) => m.group(1)!)
          .toList();

      if (serviceNames.isEmpty) return null;

      final instances = <ToolInstance>[];

      for (final name in serviceNames) {
        try {
          final qcResult = await Process.run('sc.exe', ['qc', name], runInShell: true)
              .timeout(const Duration(seconds: 5));

          if (qcResult.exitCode == 0) {
            final qcOut = qcResult.stdout as String;
            final match = RegExp(r'BINARY_PATH_NAME\s+:\s+(.*)').firstMatch(qcOut);
            if (match != null) {
              var binPath = match.group(1)!.trim();
              // 处理带引号的路径
              if (binPath.startsWith('"')) {
                final endQuote = binPath.indexOf('"', 1);
                if (endQuote != -1) binPath = binPath.substring(1, endQuote);
              } else {
                // 处理带参数的情况
                final firstSpace = binPath.indexOf(' ');
                if (firstSpace != -1) binPath = binPath.substring(0, firstSpace);
              }

              String? version;
              try {
                // 尝试 mysqld 或 mysql 获取版本
                final mysqlExe = binPath.toLowerCase().contains('mysqld')
                    ? binPath.replaceAll('mysqld', 'mysql')
                    : binPath;

                var vRes = await Process.run(mysqlExe, ['--version'], runInShell: true)
                    .timeout(const Duration(seconds: 5));

                if (vRes.exitCode != 0) {
                  vRes = await Process.run(binPath, ['--version'], runInShell: true)
                      .timeout(const Duration(seconds: 5));
                }

                if (vRes.exitCode == 0) {
                  version = _extractVersion(vRes.stdout as String, null);
                }
              } catch (_) {}

              instances.add(ToolInstance(
                version: version ?? '未知版本',
                path: binPath,
                name: name,
              ));
            }
          }
        } catch (_) {}
      }

      if (instances.isNotEmpty) {
        // 按版本号降序排序，最新的排前面
        instances.sort((a, b) => b.version.compareTo(a.version));

        return ScanResult(
          found: true,
          version: instances.length > 1
              ? '${instances.first.version} (等 ${instances.length} 个实例)'
              : instances.first.version,
          path: instances.first.path,
          instances: instances,
          extra: {
            '总实例数': '${instances.length} 个',
            '服务列表': serviceNames.join('、'),
          },
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<ScanResult?> _getRedisScan() async {
    if (!Platform.isWindows) return null;

    try {
      // 1. 查找所有带有 Redis 关键字的服务
      final result = await Process.run('sc.exe', ['query', 'state=', 'all'], runInShell: true)
          .timeout(const Duration(seconds: 10));

      if (result.exitCode != 0) return null;

      final out = result.stdout as String;
      final serviceNames = RegExp(r'SERVICE_NAME:\s+(Redis\S*)', caseSensitive: false)
          .allMatches(out)
          .map((m) => m.group(1)!)
          .where((name) => !name.toLowerCase().contains('redist')) // 排除 RedistService
          .toList();

      if (serviceNames.isEmpty) return null;

      final instances = <ToolInstance>[];

      for (final name in serviceNames) {
        try {
          final qcResult = await Process.run('sc.exe', ['qc', name], runInShell: true)
              .timeout(const Duration(seconds: 5));

          if (qcResult.exitCode == 0) {
            final qcOut = qcResult.stdout as String;
            final match = RegExp(r'BINARY_PATH_NAME\s+:\s+(.*)').firstMatch(qcOut);
            if (match != null) {
              var binPath = match.group(1)!.trim();
              // 处理带引号的路径
              if (binPath.startsWith('"')) {
                final endQuote = binPath.indexOf('"', 1);
                if (endQuote != -1) binPath = binPath.substring(1, endQuote);
              } else {
                // 处理带参数的情况
                final firstSpace = binPath.indexOf(' ');
                if (firstSpace != -1) binPath = binPath.substring(0, firstSpace);
              }

              String? version;
              try {
                // 尝试 redis-server 获取版本
                final dir = File(binPath).parent.path;
                final redisServerExe = '$dir\\redis-server.exe';

                var vRes = await Process.run(redisServerExe, ['--version'], runInShell: true)
                    .timeout(const Duration(seconds: 5));

                if (vRes.exitCode != 0) {
                  // 如果没有 redis-server.exe，尝试直接运行服务文件（有些发行版 RedisService.exe 就是 redis-server）
                  vRes = await Process.run(binPath, ['--version'], runInShell: true)
                      .timeout(const Duration(seconds: 5));
                }

                if (vRes.exitCode == 0) {
                  version = _extractVersion(vRes.stdout as String, RegExp(r'v=(\d+\.\d+[\.\d]*)'));
                }
              } catch (_) {}

              instances.add(ToolInstance(
                version: version ?? '未知版本',
                path: binPath,
                name: name,
              ));
            }
          }
        } catch (_) {}
      }

      if (instances.isNotEmpty) {
        instances.sort((a, b) => b.version.compareTo(a.version));

        return ScanResult(
          found: true,
          version: instances.length > 1
              ? '${instances.first.version} (等 ${instances.length} 个实例)'
              : instances.first.version,
          path: instances.first.path,
          instances: instances,
          extra: {
            '总实例数': '${instances.length} 个',
            '服务列表': serviceNames.join('、'),
          },
        );
      }
    } catch (_) {}
    return null;
  }
}

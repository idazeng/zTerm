/// 主机信息模型（用于终端上方信息条）
class HostInfo {
  /// 主机名
  final String hostname;
  
  /// IP 地址
  final String ipAddress;
  
  /// 系统类型（如 Linux, Ubuntu 等）
  final String systemType;
  
  /// 系统版本
  final String systemVersion;
  
  /// 系统代号（如 Trixie, Noble 等）
  final String systemCodename;
  
  /// 在线时长
  final String uptime;
  
  /// CPU 使用率
  final double cpuUsage;
  
  /// 内存使用率
  final double memoryUsage;
  
  /// 内存总量（MB）
  final int memoryTotal;
  
  /// 内存已用（MB）
  final int memoryUsed;
  
  /// 磁盘使用率
  final double diskUsage;
  
  /// 磁盘总量（GB）
  final int diskTotal;
  
  /// 磁盘已用（GB）
  final int diskUsed;
  
  /// 系统负载
  final List<double> loadAverage;

  HostInfo({
    this.hostname = '',
    this.ipAddress = '',
    this.systemType = '',
    this.systemVersion = '',
    this.systemCodename = '',
    this.uptime = '',
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.memoryTotal = 0,
    this.memoryUsed = 0,
    this.diskUsage = 0.0,
    this.diskTotal = 0,
    this.diskUsed = 0,
    this.loadAverage = const [],
  });

  /// 创建副本
  HostInfo copyWith({
    String? hostname,
    String? ipAddress,
    String? systemType,
    String? systemVersion,
    String? systemCodename,
    String? uptime,
    double? cpuUsage,
    double? memoryUsage,
    int? memoryTotal,
    int? memoryUsed,
    double? diskUsage,
    int? diskTotal,
    int? diskUsed,
    List<double>? loadAverage,
  }) {
    return HostInfo(
      hostname: hostname ?? this.hostname,
      ipAddress: ipAddress ?? this.ipAddress,
      systemType: systemType ?? this.systemType,
      systemVersion: systemVersion ?? this.systemVersion,
      systemCodename: systemCodename ?? this.systemCodename,
      uptime: uptime ?? this.uptime,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      memoryTotal: memoryTotal ?? this.memoryTotal,
      memoryUsed: memoryUsed ?? this.memoryUsed,
      diskUsage: diskUsage ?? this.diskUsage,
      diskTotal: diskTotal ?? this.diskTotal,
      diskUsed: diskUsed ?? this.diskUsed,
      loadAverage: loadAverage ?? this.loadAverage,
    );
  }

  /// 获取内存显示字符串
  String get memoryDisplay {
    if (memoryTotal == 0) return '--';
    return '${memoryUsed}MB / ${memoryTotal}MB (${(memoryUsage * 100).toStringAsFixed(1)}%)';
  }

  /// 获取磁盘显示字符串
  String get diskDisplay {
    if (diskTotal == 0) return '--';
    return '${diskUsed}GB / ${diskTotal}GB (${(diskUsage * 100).toStringAsFixed(1)}%)';
  }

  /// 获取负载显示字符串
  String get loadDisplay {
    if (loadAverage.isEmpty) return '--';
    return loadAverage.map((e) => e.toStringAsFixed(2)).join(' / ');
  }
}

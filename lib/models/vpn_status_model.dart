class OpenVpnStatus {
   String stage;
  String? connectedOn;
  final int byteIn;
  final int byteOut;
  final int packetsIn;
  final int packetsOut;
  final Duration  duration;

  OpenVpnStatus({
    required this.stage,
     this.connectedOn,
    required this.byteIn,
    required this.byteOut,
    required this.packetsIn,
    required this.packetsOut,
    required this.duration,
  });

  // Updated fromJson method to handle type mismatches
  factory OpenVpnStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('JSON data cannot be null');
    }
    return OpenVpnStatus(
      stage: json['connected_on'] != null ? 'connected' : 'disconnected',
      connectedOn: json['connected_on'] != null
          ? (json['connected_on'] as DateTime).toIso8601String() // Convert DateTime to ISO string
          : null,
      byteIn: _parseInt(json['byte_in']),
      byteOut: _parseInt(json['byte_out']),
      packetsIn: _parseInt(json['packets_in']),
      packetsOut: _parseInt(json['packets_out']),
     duration: _parseDuration(json['duration']), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'byte_in': byteIn,
      'byte_out': byteOut,
      'packets_in': packetsIn,
      'packets_out': packetsOut,
      'duration': duration.inSeconds,
      'connected_on': connectedOn,
    };
  }

  // Helper function to safely parse integers from dynamic values
  static int _parseInt(dynamic value) {
    if (value is String) {
      return int.tryParse(value) ?? 0;  // Try to parse string to int, default to 0 if it fails
    } else if (value is int) {
      return value;  // Already an int, return as is
    }
    return 0;  // Default if the value is neither a string nor an int
  }
  static Duration _parseDuration(dynamic value) {
    if (value is String) {
      final parts = value.split(":");
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }
    return Duration.zero;
  }

  // Method to format Duration into "HH:MM:SS" format
  String get formattedDuration {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    // Pad with leading zeros if necessary
    return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  // Helper function to format numbers as two digits (e.g., "09" instead of "9")
  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

}

import '../data/ecg_stream_buffer.dart';
import '../models/ecg_data_point.dart';

class EcgRepository {
  final EcgStreamBuffer buffer;

  EcgRepository(this.buffer);

  List<EcgDataPoint> readSamples({int batchSize = 4}) {
    final List<EcgDataPoint> result = [];

    buffer.buffers.forEach((_, samples) {
      final take = samples.length >= batchSize
          ? batchSize
          : samples.length;

      for (int i = 0; i < take; i++) {
        result.add(
          EcgDataPoint(
            value: samples.removeAt(0).toDouble(),
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    return result;
  }
}

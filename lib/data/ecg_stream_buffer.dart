class EcgStreamBuffer {
  final Map<int, List<int>> _buffers = {};

  void addSample(int lead, int value) {
    _buffers.putIfAbsent(lead, () => []);
    _buffers[lead]!.add(value);
  }

  Map<int, List<int>> get buffers => _buffers;
}

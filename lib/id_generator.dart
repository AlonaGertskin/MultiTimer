int _lastId = 0;

int newId() {
  final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
  _lastId = id > _lastId ? id : _lastId + 1;
  return _lastId;
}

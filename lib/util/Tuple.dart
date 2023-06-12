class Tuple<X,Y> {
  Tuple(this._left, this._right);
  X _left;
  Y _right;

  X get getLeft {
    return _left;
  }

  Y get getRight {
    return _right;
  }

  void setLeft(left) {
    _left = left;
  }

  void setRight(right) {
    _right = right;
  }

  @override
  String toString() {
    return 'Tuple{_left: $_left, _right: $_right}';
  }

}
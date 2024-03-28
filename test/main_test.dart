import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    "should be return a 2",
    () {
      //setup
      var sum = 0;
      const mockResult = 2;
      //arrange
      sum = 1 + 1;
      //assert
      expect(sum, mockResult);
    },
  );
}

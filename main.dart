import 'dart:io';

void main(List<String> args) async {
  try {
    var filename = args[0];
    var file = File(args[0]);
    var contents = await file.readAsLines();
  } catch (e) {
    print('Raise an exception when read file.');
    print(e);
    return;
  }
}

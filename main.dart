import 'dart:io';

import 'assembler.dart';

Future<Assembler> initParser(String filename) async {
  var inputs = await File(filename).readAsLines();
  return Assembler(
      filename: filename.substring(0, filename.indexOf('.')),
      instructions: inputs
          .where((x) => x.isNotEmpty && x[0] != '.')
          .map(
              (x) => x.split(RegExp(r'\s')).where((x) => x.isNotEmpty).toList())
          .toList());
}

void main(List<String> args) async {
  var parser = null;

  try {
    parser = await initParser(args[0]);
  } catch (e) {
    print('Raise an exception when read file.');
    print(e);
    return;
  }

  print(parser.instructions);
  parser.pass1();
  print(parser.symbols);
}

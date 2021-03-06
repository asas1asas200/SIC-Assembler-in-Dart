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
  assert(parser.proglen >= 0);
  parser.pass2();
  assert(parser.proglen >= 0);
  print('---------------Obj file---------------');
  parser.obj.forEach((line) => stdout.write(line));
  print('\n--------------------------------------');

  print('Dump file: ${parser.filename}.obj');
  parser.dump();
}

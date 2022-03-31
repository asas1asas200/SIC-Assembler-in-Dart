class Assembler {
  final String filename;
  final List<List<String>> instructions;
  final List<String> obj;
  Map<String, int> symbols;
  int proglen;

  static const Map<String, int> opTable = {
    'ADD': 0x18,
    'AND': 0x40,
    'COMP': 0x28,
    'DIV': 0x24,
    'J': 0x3C,
    'JEQ': 0x30,
    'JGT': 0x34,
    'JLT': 0x38,
    'JSUB': 0x48,
    'LDA': 0x00,
    'LDCH': 0x50,
    'LDL': 0x08,
    'LDX': 0x04,
    'MUL': 0x20,
    'OR': 0x44,
    'RD': 0xD8,
    'RSUB': 0x4C,
    'STA': 0x0C,
    'STCH': 0x54,
    'STL': 0x14,
    'STSW': 0xE8,
    'STX': 0x10,
    'SUB': 0x1C,
    'TD': 0xE0,
    'TIX': 0x2C,
    'WD': 0xDC
  };

  Assembler(
      {required this.filename, required List<List<String>> this.instructions})
      : obj = [],
        proglen = 0,
        symbols = {} {}

  bool hasLabel(List<String> line) =>
      line.length != 1 && !opTable.containsKey(line[0]);

  int getStarting() {
    if (instructions[0][0] == 'START') {
      return int.parse(instructions[0][1], radix: 16);
    } else if (instructions[0][1] == 'START') {
      return int.parse(instructions[0][2], radix: 16);
    }
    return 0;
  }

  //TODO: Thrown exception when failed.
  void pass1() {
    int locctr = getStarting();
    int starting = locctr;

    instructions.skip(1).forEach((line) {
      String opcode;
      String label;
      if (hasLabel(line)) {
        label = line[0];
        opcode = line[1];
        this.symbols[label] = locctr;
      } else {
        opcode = line[0];
      }

      if (opTable.containsKey(opcode) || opcode == 'WORD') {
        locctr += 3;
      } else if (opcode == 'BYTE') {
        final operand = line[2];
        int operandlen = 0;
        if (operand[0] == 'X')
          operandlen = (operand.length - 3) ~/ 2;
        else if (operand[0] == 'C') operandlen = operand.length - 3;

        locctr += operandlen;
      } else if (opcode == 'RESB') {
        locctr += int.parse(line[2]);
      } else if (opcode == 'RESW') {
        locctr += int.parse(line[2]) * 3;
      }
    });

    this.proglen = locctr - starting;
  }

  void pass2() {
    String toFormattedHex(int num, [int pad = 6]) =>
        num.toRadixString(16).toUpperCase().padLeft(pad, '0');

    String makeIns(String opcode, String operand) {
      int ins = opTable[opcode]! * 65536;
      if (operand.isNotEmpty) {
        if (operand.substring(operand.length - 2) == ',X') {
          ins += 32768;
          operand = operand.substring(0, operand.length - 2);
        }

        if (symbols.containsKey(operand)) {
          ins += symbols[operand]!;
        } else {
          return "";
        }
      }

      return toFormattedHex(ins);
    }

    this.obj.clear();
    int locctr = getStarting();
    int starting = locctr;

    // Header
    String name = instructions[0][0] == 'START' ? '' : instructions[0][0];
    this.obj.add('H'
        '${name.padRight(6, ' ')}'
        '${toFormattedHex(starting)}'
        '${toFormattedHex(proglen)}'
        '\n');

    String tline = "";
    int tstart = locctr;

    instructions.skip(1).forEach((line) {
      String opcode;
      String operand = '';
      if (hasLabel(line)) {
        opcode = line[1];
        if (line.length == 3) operand = line[2];
      } else {
        opcode = line[0];
        if (line.length == 2) operand = line[1];
      }

      if (line[0] == 'END') {
        if (tline.length > 0) {
          this.obj.add('T'
              '${toFormattedHex(tstart)}'
              '${toFormattedHex((tline.length / 2).floor(), 2)}'
              '$tline'
              '\n');
        }

        int addr = starting;
        if (line.length == 2) addr = symbols[line[1]]!;

        this.obj.add('E' '${toFormattedHex(addr)}');
      } else if (opTable.containsKey(opcode)) {
        String ins = makeIns(opcode, operand);
        assert(ins.isNotEmpty);
        if (ins.isEmpty) return; //FIXME
        if (locctr + 3 - tstart > 30) {
          this.obj.add('T'
              '${toFormattedHex(tstart)}'
              '${toFormattedHex((tline.length / 2).floor(), 2)}'
              '$tline'
              '\n');
          tstart = locctr;
          tline = ins;
        } else {
          tline += ins;
        }
        locctr += 3;
      } else if (opcode == 'WORD') {
        String cons = toFormattedHex(int.parse(operand));

        if (locctr + 3 - tstart > 30) {
          this.obj.add('T'
              '${toFormattedHex(tstart)}'
              '${toFormattedHex((tline.length / 2).floor(), 2)}'
              '$tline'
              '\n');
          tstart = locctr;
          tline = cons;
        } else {
          tline += cons;
        }
        locctr += 3;
      } else if (opcode == 'BYTE') {
        int operandlen = 0;
        String cons = '';
        if (operand[0] == 'X') {
          operandlen = (operand.length - 3) ~/ 2;
          cons = operand.substring(2, operand.length - 1);
        } else if (operand[0] == 'C') {
          operandlen = operand.length - 3;
          operand.substring(2, operand.length - 1).runes.forEach((c) {
            cons += toFormattedHex(c, 2);
          });
        }

        if (locctr + operandlen - tstart > 30) {
          this.obj.add('T'
              '${toFormattedHex(tstart)}'
              '${toFormattedHex((tline.length / 2).floor(), 2)}'
              '$tline'
              '\n');
          tstart = locctr;
          tline = cons;
        } else {
          tline += cons;
        }
        locctr += operandlen;
      } else if (opcode == 'RESB') {
        locctr += int.parse(operand);
      } else if (opcode == 'RESW') {
        locctr += int.parse(operand) * 3;
      } //FIXME: Thown exception when failed.
    });
    this.proglen = locctr - starting;
  }
}

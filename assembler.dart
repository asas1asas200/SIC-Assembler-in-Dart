class Assembler {
  final String filename;
  final List<List<String>> instructions;
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
      : proglen = 0,
        symbols = {} {}

  //TODO: Thrown exception when failed.
  void pass1() {
    bool hasLabel(List<String> line) =>
        line.length != 1 && !opTable.containsKey(line[0]);

    int locctr = 0;
    if (instructions[0][0] == 'START') {
      locctr = int.parse(instructions[0][1], radix: 16);
    } else if (instructions[0][1] == 'START') {
      locctr = int.parse(instructions[0][2], radix: 16);
    }
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
}

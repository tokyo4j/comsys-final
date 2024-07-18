import re
from argparse import ArgumentParser

opcodes = {
    "ADD": "0000",
    "SUB": "0001",
    "ASR": "0010",
    "RSR": "0011",
    "RSL": "0100",
    "BST": "0101",
    "BRT": "0110",
    "BTS": "0111",
    "AND": "1000",
    "OR": "1001",
    "NAD": "1010",
    "XOR": "1011",
    "MUL": "1100",
    "EXT": "1101",
    "THA": "1110",
    "THB": "1111",
}

regs = {
    "r0": "00",
    "r1": "01",
    "r2": "10",
    "r3": "11",
}

flags = {
    "_": "000",
    "Z": "001",
    "NZ": "010",
    "G": "011",
    "GE": "100",
    "L": "101",
    "LE": "110",
}


def remove_brackets(tokens):
    return list(map(lambda token: token.replace("[", "").replace("]", ""), tokens))


def imm_format(v, width=8):
    v = v & ((1 << width) - 1)
    v = f"{v:0{width}b}"
    # Insert underscores every 4 bits
    v = "_".join([v[i : i + 4] for i in range(0, len(v), 4)])
    return v


def parse_int(token):
    negative = False
    if token[0] == "-":
        negative = True
        token = token[1:]
    if token.startswith("0x"):
        v = int(token, 16)
    elif token.startswith("0b"):
        v = int(token, 2)
    else:
        v = int(token)
    if negative:
        v = -v
    return v


def imm(token, width=8):
    return imm_format(parse_int(token), width)


def assemble(l, labels, vars, pc):
    if match := re.search(r"\[\$(\w+)\]", l):
        # [$label] -> PC-5
        rel = labels[match.group(1)] - pc
        if rel < -128 or rel >= 128:
            print("PC relative out of range")
            exit(1)
        l = re.sub(r"\[\$\w+\]", f"[PC{rel:+d}]", l)
    elif match := re.search(r"\$(\w+)", l):
        # $label -> 123
        addr = labels[match.group(1)]
        l = re.sub(r"\$\w+", f"{addr}", l)
    if match := re.search(r"#(\w+)", l):
        # #var -> 123
        addr = vars[match.group(1)]
        l = re.sub(r"#\w+", f"{addr}", l)

    tokens = l.replace(",", " ").replace("=", " ").split()
    inst = None

    if tokens[0] == "MV":
        # MV ra=rb -> THB ra,r0,rb
        tokens = ["THB", tokens[1], "r0", tokens[2]]
    elif tokens[0] == "CMP":
        # CMP ... -> EVA SUB ...
        tokens = ["EVA", "SUB", *tokens[1:]]
    elif tokens[0] == "JP":
        # JP ... -> BR _ ...
        tokens = ["BR", "_", *tokens[1:]]
    elif tokens[0] == "INC":
        # INC ra -> ADD ra=ra, 1
        tokens = ["ADD", tokens[1], tokens[1], "1"]
    elif tokens[0] == "DEC":
        # INC ra -> SUB ra=ra, 1
        tokens = ["SUB", tokens[1], tokens[1], "1"]
    elif tokens[0] == "LILH":
        # LILH ra, 256 -> LIL ra, ra, 0 & LIH ra, ra, 1
        i = parse_int(tokens[2])
        lo = i & 0xFF
        hi = (i & 0xFF00) >> 8
        return [
            assemble(f"LIL {tokens[1]}, {tokens[1]}, {lo}", labels, vars, pc),
            assemble(f"LIH {tokens[1]}, {tokens[1]}, {hi}", labels, vars, pc + 1),
        ]

    if tokens[0] == "NOP":
        # NOP
        inst = "0000_0000_0000_0000"
    elif tokens[0] == "HALT":
        # HALT
        inst = "0000_0000_0000_0001"
    elif tokens[0] == "SEND":
        # SEND r0, r1, 2
        inst = (
            "0000_1100_"
            + regs[tokens[1]]
            + regs[tokens[2]]
            + "_"
            + imm(tokens[3], width=4)
        )
    elif tokens[0] == "EVA":
        if re.match(r"r\d", tokens[3]):
            # EVA ADD r0, r1
            inst = (
                "0000_0001_"
                + opcodes[tokens[1]]
                + "_"
                + regs[tokens[2]]
                + regs[tokens[3]]
            )
        else:
            # EVA ADD r0, 1
            if tokens[1] == "ADD":
                op = "0"
            elif tokens[1] == "SUB":
                op = "1"
            else:
                op = "ERROR"
            inst = "1000_1" + op + regs[tokens[2]] + "_" + imm(tokens[3])
    elif tokens[0] == "LI":
        if tokens[2] == "SR":
            # LI r0, SR
            inst = "0110_" + regs[tokens[1]] + "00_0000_0000"
        else:
            # LI r0, -1111
            inst = "0000_01" + regs[tokens[1]] + "_" + imm(tokens[2])
    elif tokens[0] == "LIL":
        # LIL r0, r1, 3
        inst = "0100_" + regs[tokens[1]] + regs[tokens[2]] + "_" + imm(tokens[3])
    elif tokens[0] == "LIH":
        # LIH r0, r1, 3
        inst = "0101_" + regs[tokens[1]] + regs[tokens[2]] + "_" + imm(tokens[3])
    elif tokens[0] == "SM":
        if re.match(r"\[\d+\]", tokens[1]):
            # SM [1]=r3
            tokens = remove_brackets(tokens)
            inst = "0000_10" + regs[tokens[2]] + "_" + imm(tokens[1])
        # elif re.match(r"\[r\d\]", tokens[1]):
        #     # SM [r0]=r1
        #     tokens = remove_brackets(tokens)
        #     inst = (
        #         "0110_0010_" + opcodes["THB"] + "_" + regs[tokens[1]] + regs[tokens[2]]
        #     )
        elif re.match(r"\[r\d.+\]", tokens[1]):
            # SM [r0-1]=r0
            tokens = remove_brackets(tokens)
            inst = (
                "1001_"
                + regs[tokens[1][:2]]
                + regs[tokens[2]]
                + "_"
                + imm(tokens[1][2:])
            )
    elif tokens[0] == "LM":
        if re.match(r"\[[+-]?\d+\]", tokens[2]):
            # LM r0=[1]
            tokens = remove_brackets(tokens)
            inst = "1000_00" + regs[tokens[1]] + "_" + imm(tokens[2])
        elif tokens[2][1:] in opcodes:
            # LM r0=[ADD r0, r2]
            tokens = remove_brackets(tokens)
            inst = (
                "1010_"
                + regs[tokens[1]]
                + "00_"
                + opcodes[tokens[2]]
                + "_"
                + regs[tokens[3]]
                + regs[tokens[4]]
            )
        elif re.match(r"\[r\d[+-]\d+\]", tokens[2]):
            # LM r2=[r1-3]
            tokens = remove_brackets(tokens)
            inst = (
                "1011_"
                + regs[tokens[1]]
                + regs[tokens[2][:2]]
                + "_"
                + imm(tokens[2][2:])
            )
    elif tokens[0] == "BR":
        if tokens[2][1:] in opcodes:
            # BR NZ [SUB r0, r1]
            tokens = remove_brackets(tokens)
            inst = (
                "0001_0"
                + flags[tokens[1]]
                + "_"
                + opcodes[tokens[2]]
                + "_"
                + regs[tokens[3]]
                + regs[tokens[4]]
            )
        elif re.match(r"\[[+-]?\d\]", tokens[2]):
            # BR C [1]
            tokens = remove_brackets(tokens)
            inst = "0001_1" + flags[tokens[1]] + "_" + imm(tokens[2])
        elif tokens[2][1:3] == "PC":
            # BR NS [PC-1]
            tokens = remove_brackets(tokens)
            inst = "0010_0" + flags[tokens[1]] + "_" + imm(tokens[2][2:])
        elif re.match(r"\[r\d[+-]\d+\]", tokens[2]):
            # BR C [r0-1]
            tokens = remove_brackets(tokens)
            inst = (
                "111"
                + "_".join(regs[tokens[2][:2]])
                + flags[tokens[1]]
                + "_"
                + imm(tokens[2][2:])
            )
    elif tokens[0] in opcodes:
        if re.match(r"r\d", tokens[3]):
            # AND r1=r1,r2
            inst = (
                "0010_10"
                + regs[tokens[1]]
                + "_"
                + opcodes[tokens[0]]
                + "_"
                + regs[tokens[2]]
                + regs[tokens[3]]
            )
        elif re.match(r"[+-]?\d+", tokens[3]):
            # ADD r1=r0,123
            if tokens[0] == "ADD":
                op = "0"
            elif tokens[0] == "SUB":
                op = "1"
            else:
                op = "ERROR"
            inst = (
                "110"
                + op
                + "_"
                + regs[tokens[1]]
                + regs[tokens[2]]
                + "_"
                + imm(tokens[3])
            )
    return inst


arg_parser = ArgumentParser()
arg_parser.add_argument("files", nargs="+")
*in_filenames, out_filename = arg_parser.parse_args().files

lines = []
for in_filename in in_filenames:
    with open(in_filename) as f:
        lines += f.readlines()

labels = {}
vars = {}
pc = 0

for l in lines:
    l = l.strip()
    if l == "" or l[0:2] == "//":
        continue
    if match := re.search(r"^(\w+):", l):
        labels[match.group(1)] = pc
        continue
    if match := re.search(r"^#(\w+)=(\d+)", l):
        vars[match.group(1)] = parse_int(match.group(2))
        continue
    if l[:4] == "LILH":
        pc += 1
    pc += 1

spaces = " " * 36
pc = 0
insts = []
for line in lines:
    l = line.strip()
    line = line[:-1]

    if (
        l == ""
        or l[0:2] == "//"
        or re.search(r"^\w+:", l)
        or re.search(r"^#\w+=\d+", l)
    ):
        insts.append(spaces + "// " + line)
        continue
    if (i := l.find("//")) != -1:
        l = l[:i]
    inst = assemble(l, labels, vars, pc)
    if type(inst) == list:
        assert len(inst) == 2
        insts.append(f"8'h{pc:02x}: o = 16'b{inst[0]}; // {line}")
        pc += 1
        insts.append(f"8'h{pc:02x}: o = 16'b{inst[1]}; //")
        pc += 1
    else:
        insts.append(f"8'h{pc:02x}: o = 16'b{inst}; // {line}")
        pc += 1

insts = list(map(lambda s: s.rstrip(), insts))

with open(out_filename, "w") as f:
    f.write("\n".join(insts))

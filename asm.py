import re

"""
NOP
HALT
EVA ADD r0, r1
LI r0, -1111
SM [1]=r3
SEND r0, r1, 2
BR NZ [SUB r0, r1]
BR C [1]
BR NS [PC-1]
AND r1=r1,r2
LIL r0, r1, 3
LIH r0, r1, 5
LI r0, SR
SM [r0]=r1
LM r0=[1]
SM [r0-1]=r1
LM r0=[ADD r0, r2]
LM r2=[r1-3]
ADD r1=r0,123
BR C [r0-1]
"""

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
    "Z": "101",
    "NZ": "001",
    "C": "110",
    "NC": "010",
    "S": "111",
    "NS": "011",
}


def remove_brackets(tokens):
    return list(map(lambda token: token.replace("[", "").replace("]", ""), tokens))


def imm(token, width=8):
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
    v = v & ((1 << width) - 1)
    v = f"{v:0{width}b}"
    # Insert underscores every 4 bits
    v = "_".join([v[i : i + 4] for i in range(0, len(v), 4)])
    return v


def assemble(l):
    tokens = l.replace(",", " ").replace("=", " ").split()
    inst = None

    if tokens[0] == "MV":
        # MV ra=rb -> THB ra,r0,rb
        tokens = ["THB", tokens[1], "r0", tokens[2]]
    elif tokens[0] == "CMP":
        # CMP ra,rb -> EVA SUB ra,rb
        tokens = ["EVA", "SUB", tokens[1], tokens[2]]

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
        # EVA ADD r0, r1
        inst = (
            "0000_0001_" + opcodes[tokens[1]] + "_" + regs[tokens[2]] + regs[tokens[3]]
        )
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
        elif re.match(r"\[r\d\]", tokens[1]):
            # SM [r0]=r1
            tokens = remove_brackets(tokens)
            inst = (
                "0110_0010_" + opcodes["THB"] + "_" + regs[tokens[1]] + regs[tokens[2]]
            )
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


f = open("inst-primary.txt")
pc = 0

for l in f.readlines():
    l = l.strip()
    comment = ""
    if l == "" or l[0:2] == "//":
        print(l)
        continue
    if (i := l.find("//")) != -1:
        comment = " " + l[i:]
        l = l[:i]
    inst = assemble(l)
    print(f"5'h{pc:02x}: o = 16'b{inst}; // {l}{comment}")
    pc += 1

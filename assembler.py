import sys

instructions = ["nop", "inc", "dec", "ldi", "ld", "st", "cmp", "j", "jz", "jnz", "jc", "jnc", "add", "sub", "hlt"]
instructions = {k: v if k != "hlt" else 0xFF for v, k in enumerate(instructions)}

def main(argv: list[str]) -> int:
    result = bytearray()

    with open(argv[1], "r") as file:
        lines = file.readlines()

    labels, address = {}, 0

    for line in lines:
        line = line.strip()

        if line == "":
            continue

        if line.endswith(":"):
            labels[line[:-1]] = address.to_bytes(1)
            continue

        instruction, *operands = line.split(" ")
        address += 1 + len(operands)

    for line in lines:
        line = line.strip()

        if line == "":
            continue

        if line.endswith(":"):
            continue

        instruction, *operands = line.split(" ")

        if instruction.lower() not in instructions:
            raise SyntaxError(f"Unknown instruction '{instruction}'")

        result += instructions[instruction].to_bytes(1)

        for operand in operands:
            if operand in labels:
                result += labels[operand]
                continue

            base = 10

            if operand.startswith("0x"):
                operand = operand[2:]
                base = 16

            elif operand.startswith("0o"):
                operand = operand[2:]
                base = 8

            elif operand.startswith("0b"):
                operand = operand[2:]
                base = 2

            result += int(operand, base).to_bytes(1)

    with open("ram.sv", "r") as file:
        content = file.read()
        start = content.find("initial begin")
        generated = content[:start + 14]

        for index, byte in enumerate(result):
            generated += f"    mem[{index}] = 8'h{format(byte, "02X")};\n"

        end = content.find("end", start)
        generated += content[end:]

    with open("ram.sv", "w") as file:
        file.write(generated)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
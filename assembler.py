import sys, re

instructions = [
    "nop", "ldi", "ld", "st", "cmp", "j", "jz", "jnz", "jc", "jnc",
    "add", "sub", "and", "or", "xor", "not", "shl", "shr", "hlt"
]

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
            labels[line[:-1]] = address
            continue

        address += 1

    for line in lines:
        line = line.strip()

        if line == "":
            continue

        if line.endswith(":"):
            continue

        instruction, *operands = re.split(r"[,\s]+", line)

        if instruction.lower() not in instructions:
            raise SyntaxError(f"Unknown instruction '{instruction}'")

        index = 32
        index -= 8
        instruction = (instructions.index(instruction) if instruction != instructions[-1] else 0xFF) << index

        for operand in operands:
            if operand in labels:
                index -= index
                instruction |= labels[operand]
                continue

            if operand.startswith("x"):
                index -= 5
                instruction |= int(operand[1:]) << index
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

            index -= index
            instruction |= int(operand, base) << index

        result += instruction.to_bytes(4, "big")

    with open("ram.sv", "r") as file:
        content = file.read()
        start = content.find("initial begin")
        generated = content[:start + 14]

        for index in range(int(len(result) / 4)):
            instruction = int.from_bytes(result[index * 4:index * 4 + 4], "big")
            generated += f"    mem[{index}] = 32'h{format(instruction, "08X")};\n"

        end = content.find("end", start)
        generated += content[end:]

    with open("ram.sv", "w") as file:
        file.write(generated)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
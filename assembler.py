import sys

instructions = {
    "nop": 0x00,
    "inc": 0x01,
    "dec": 0x02,
    "ldi": 0x03,
    "ld": 0x04,
    "st": 0x05,
    "hlt": 0xFF
}

def main(argv: list[str]) -> int:
    result = bytearray()

    with open(argv[1], "r") as file:
        lines = file.readlines()

    for line in lines:
        instruction, *operands = line.strip().split(" ")

        if instruction.lower() not in instructions:
            raise SyntaxError(f"Unknown instruction '{instruction}'")

        result += instructions[instruction].to_bytes(1)

        for operand in operands:
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
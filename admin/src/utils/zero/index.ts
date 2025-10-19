export function emptyToNull(obj: object): object {
  return Object.keys(obj).reduce((acc, key) => {
    const value = obj[key];
    if (value === "" || value === undefined || value === null) {
      acc[key] = null;
    } else {
      acc[key] = value;
    }
    return acc;
  }, {} as object);
}

const RADIX_CHARS: string[] = [
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z"
];

/**
 * Base conversion
 *
 * @param input Source string
 * @param fromBase Source base
 * @param toBase Target base
 * @return Target string
 */
export function radixConvert(
  input: string,
  fromBase: number,
  toBase: number
): string | null {
  const isValid: boolean = radixCheck(input, fromBase, toBase);
  if (!isValid) {
    return null;
  }
  const fromChars: string[] = RADIX_CHARS.slice(0, fromBase);
  const inputChars: string[] = input.split("");
  let num: bigint = BigInt(0);
  for (
    let i: number = 0, j: number = inputChars.length - 1;
    i < inputChars.length && j >= 0;
    i++, j--
  ) {
    const x: number = fromChars.indexOf(inputChars[i]);
    const d: bigint = BigInt(Math.pow(fromBase, j));
    num = num + BigInt(d * BigInt(x));
  }
  if (num === BigInt(0)) {
    return "0";
  }
  let result: string = "";
  while (num > BigInt(0)) {
    const [quotient, remainder]: bigint[] = [
      num / BigInt(toBase),
      num % BigInt(toBase)
    ];
    result = RADIX_CHARS[Number(remainder)] + result;
    num = quotient;
  }
  return result;
}

/**
 * Validate base conversion parameters
 *
 * @param input Source N-base string
 * @param fromBase Source base
 * @param toBase Target base
 * @return Whether the parameters are valid
 */
function radixCheck(input: string, fromBase: number, toBase: number): boolean {
  if (!input || input.length === 0) {
    return false;
  }
  if (
    fromBase <= 0 ||
    fromBase > RADIX_CHARS.length ||
    toBase <= 0 ||
    toBase > RADIX_CHARS.length
  ) {
    return false;
  }
  const fromChars = RADIX_CHARS.slice(0, fromBase);
  for (const c of input) {
    if (fromChars.indexOf(c) < 0) {
      return false;
    }
  }
  return true;
}

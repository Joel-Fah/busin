import QRCode from "qrcode";

/**
 * How the boarding code is drawn on the web ticket: each dark module as a round dot, and the three finder patterns (the
 * corner squares a scanner looks for first) kept square, drawn whole. Error correction stays at Q.
 */
export type QrArt = { size: number; dots: [number, number][]; finders: [number, number][] };

/** True for a module inside one of the three 7 by 7 finder patterns. */
function inFinder(row: number, col: number, size: number): boolean {
  const near = (v: number, start: number) => v >= start && v < start + 7;
  return (near(row, 0) && near(col, 0)) || (near(row, 0) && near(col, size - 7)) || (near(row, size - 7) && near(col, 0));
}

export function qrArt(text: string): QrArt {
  const { modules } = QRCode.create(text, { errorCorrectionLevel: "Q" });
  const size = modules.size;
  const dots: [number, number][] = [];
  for (let row = 0; row < size; row++) {
    for (let col = 0; col < size; col++) {
      if (modules.get(row, col) && !inFinder(row, col, size)) dots.push([col, row]);
    }
  }
  return { size, dots, finders: [[0, 0], [size - 7, 0], [0, size - 7]] };
}

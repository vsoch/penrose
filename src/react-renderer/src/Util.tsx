export const toScreen = (
  [x, y]: [number, number],
  canvasSize: [number, number]
) => {
  const [width, height] = canvasSize;
  return [width / 2 + x, height / 2 - y];
};
export const toHex = (rgba: [number, number, number, number]) => {
  return rgba.slice(0, 3).reduce((prev, cur) => {
    const hex = Math.round(255 * cur).toString(16);
    const padded = hex.length === 1 ? "0" + hex : hex;
    return prev + padded;
  }, "#");
};

const isLabelSized = ([type, obj]: [string, any]) => {
  if (type === "Text") {
    return obj.w.contents !== 0 && obj.h.contents !== 0;
  }
  return true;
};

const isLabelBlank = ([type, obj]: [string, any]) => {
  return type === "Text" && obj.string.contents === "";
};

export const hydrated = (shapes: any[]) =>
  shapes.every(isLabelBlank) || shapes.every(isLabelSized);
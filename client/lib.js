const createElementFromString = (string) => {
  const el = document.createElement('div');
  el.innerHTML = string;
  return el.firstChild;
};

const parseTuple = (string) => {
  const items = [];
  string.replaceAll(/\[|\"|\]/g, "").split(",").map((item) => {
    items.push(BigInt(item));
  });
  return items;
}

const parseNestedTuple = (string) => {
  return eval(string);
}

module.exports = { 
  createElementFromString, parseTuple,
  parseNestedTuple
}
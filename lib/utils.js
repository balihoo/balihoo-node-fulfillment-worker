exports.startsWith = function(haystack, needle) {
  return haystack.slice(0, needle.length) === needle;
};

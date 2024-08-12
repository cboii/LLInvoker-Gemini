exports.setLanguage = (language) => {
  let origin; let target;
  switch (language) {
    case "eng_de":
      origin = "English";
      target = "German";
      break;
    case "eng_fr":
      origin = "English";
      target = "French";
      break;
    case "fr_de":
      origin = "French";
      target = "German";
      break;
    default:
      return null;
  }
  return {origin, target};
};

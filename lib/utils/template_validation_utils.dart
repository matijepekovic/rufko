bool validateTemplateName(String name, {int minLength = 3}) {
  return name.trim().length >= minLength;
}

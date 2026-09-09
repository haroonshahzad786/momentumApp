module.exports = {
  root: true,
  extends: ['@react-native-community', 'plugin:prettier/recommended'],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  "rules": {
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": ["off"]
  },
};

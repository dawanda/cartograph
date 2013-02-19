config = module.exports;

config["Browser tests"] = {
  env: "browser",
  rootPath: "../",
  sources: ["lib/cartograph.js"],
  tests: ["spec/**/*.spec.{coffee,js}"],
  extensions: [require("buster-coffee")]
}

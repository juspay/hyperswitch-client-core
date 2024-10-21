const { run } = require("./prepareS3.js");
const { version } = require("../package.json");
const path = require("path");
const BASE_PATH = "mobile";

let params = {
  s3Bucket: process.env.BUCKET_NAME,
  distributionId: process.env.DIST_ID,
  urlPrefix: `v${version.split(".")[0]}`,
  version: `${BASE_PATH}/${version}`,
  distFolder: path.resolve(__dirname, "..", "reactNativeWeb/dist"),
  region: process.env.AWS_REGION,
};

run(params);
const { PutObjectCommand } = require("@aws-sdk/client-s3");
const {
  CreateInvalidationCommand,
  GetDistributionConfigCommand,
  UpdateDistributionCommand,
  GetInvalidationCommand,
  CloudFrontClient,
} = require("@aws-sdk/client-cloudfront");
const FileSystem = require("fs");
const { globSync } = require("fast-glob");
const Mime = require("mime-types");
const { S3Client } = require("@aws-sdk/client-s3");

const CACHE_CONTROL = "max-age=315360000";
const EXPIRATION_DATE = "Thu, 31 Dec 2037 23:55:55 GMT";

function withSlash(str) {
  return typeof str === "string" ? `/${str}` : "";
}

function withHyphen(str) {
  return typeof str === "string" ? `${str}-` : "";
}

function createCloudFrontClient(region) {
  return new CloudFrontClient({ region });
}

function createS3Client(region) {
  return new S3Client({ region });
}

async function doInvalidation(distributionId, urlPrefix, region, s3Bucket) {
  const cloudfrontClient = createCloudFrontClient(region);
  const cloudfrontInvalidationRef = new Date().toISOString();

  const cfParams = {
    DistributionId: distributionId,
    InvalidationBatch: {
      CallerReference: cloudfrontInvalidationRef,
      Paths: {
        Quantity: s3Bucket === process.env.S3_SANDBOX_BUCKET ? 2 : 1,
        Items:
          s3Bucket === process.env.S3_SANDBOX_BUCKET
            ? [`${withSlash(urlPrefix)}/*`, `${withSlash("v0")}/*`]
            : [`${withSlash(urlPrefix)}/*`],
      },
    },
  };

  const command = new CreateInvalidationCommand(cfParams);
  let response = await cloudfrontClient.send(command);
  const invalidationId = response.Invalidation.Id;
  let retryCounter = 0;

  while (response.Invalidation.Status === "InProgress" && retryCounter < 100) {
    await new Promise((resolve) => setTimeout(resolve, 3000));
    const getInvalidationParams = {
      DistributionId: distributionId,
      Id: invalidationId,
    };
    const statusCommand = new GetInvalidationCommand(getInvalidationParams);
    response = await cloudfrontClient.send(statusCommand);
    retryCounter++;
  }

  if (retryCounter >= 100) {
    console.log(`Still InProgress after ${retryCounter} retries`);
  }
}

async function getDistribution(distributionId, region) {
  const getDistributionConfigCmd = new GetDistributionConfigCommand({
    Id: distributionId,
  });

  const cloudfrontClient = createCloudFrontClient(region);
  const { DistributionConfig, ETag } = await cloudfrontClient.send(
    getDistributionConfigCmd
  );

  return { DistributionConfig, ETag };
}

async function updateDistribution({
  urlPrefix,
  distributionId,
  version,
  DistributionConfig,
  ETag,
  region,
}) {
  const cloudfrontClient = createCloudFrontClient(region);
  let matchingItem;
  matchingItem = DistributionConfig.Origins.Items.find((item) =>
    item.Id.startsWith("mobile-v1")
  );
  if (matchingItem) {
    matchingItem.OriginPath = `/${version}`;
  } else {
    const defaultItem =
      DistributionConfig.Origins.Items.find((item) => item.OriginPath === "") ||
      DistributionConfig.Origins.Items[0];

    if (defaultItem) {
      const clonedOrigin = JSON.parse(JSON.stringify(defaultItem));
      clonedOrigin.Id = `${withHyphen(urlPrefix)}${clonedOrigin.Id}`;
      clonedOrigin.OriginPath = `/${version}`;

      DistributionConfig.Origins.Items.unshift(clonedOrigin);
      DistributionConfig.Origins.Quantity += 1;

      if (DistributionConfig.CacheBehaviors.Items.length > 0) {
        const clonedBehavior = JSON.parse(
          JSON.stringify(DistributionConfig.CacheBehaviors.Items[0])
        );
        if (urlPrefix) clonedBehavior.PathPattern = `${urlPrefix}/*`;
        clonedBehavior.TargetOriginId = clonedOrigin.Id;

        DistributionConfig.CacheBehaviors.Items.unshift(clonedBehavior);
        DistributionConfig.CacheBehaviors.Quantity += 1;
      }
    }
  }

  const updateDistributionCmd = new UpdateDistributionCommand({
    DistributionConfig,
    Id: distributionId,
    IfMatch: ETag,
  });

  await cloudfrontClient.send(updateDistributionCmd);
}

async function uploadFile(s3Bucket, version, urlPrefix, distFolder, region) {
  const entries = globSync(`${distFolder}/**/*`);
  const s3Client = createS3Client(region);

  for (const val of entries) {
    const fileName = val.replace(`${distFolder}/`, "");
    const bufferData = FileSystem.readFileSync(val);
    const mimeType = Mime.lookup(val);

    const params = {
      Bucket: s3Bucket,
      Key: `${version}${withSlash(urlPrefix)}/${fileName}`,
      Body: bufferData,
      Metadata: {
        "Cache-Control": CACHE_CONTROL,
        Expires: EXPIRATION_DATE,
      },
      ContentType: mimeType,
    };

    await s3Client.send(new PutObjectCommand(params));

    if (s3Bucket === process.env.S3_SANDBOX_BUCKET) {
      const sandboxParams = {
        ...params,
        Key: `${version}${withSlash("v0")}/${fileName}`,
      };
      await s3Client.send(new PutObjectCommand(sandboxParams));
    }

    console.log(`Successfully uploaded to ${params.Key}`);
  }
}

const run = async (params) => {
  console.log("run parameters ---", params);
  let { s3Bucket, distributionId, urlPrefix, version, distFolder, region } =
    params;
  try {
    const isVersioned = urlPrefix === "v0" || urlPrefix === "v1";

    if (isVersioned) {
      await uploadFile(s3Bucket, version, "v0", distFolder, region);
      await uploadFile(s3Bucket, version, "v1", distFolder, region);
    } else {
      await uploadFile(s3Bucket, version, urlPrefix, distFolder, region);
    }
    if (s3Bucket !== process.env.S3_PROD_BUCKET) {
      const distributionInfo = await getDistribution(distributionId, region);
      console.log("distributionInfo completed");
      await updateDistribution({
        ...distributionInfo,
        distributionId,
        urlPrefix,
        version,
        region,
      });
      console.log("updateDistribution completed");
      if (isVersioned) {
        await doInvalidation(distributionId, "v0", region, s3Bucket);
        await doInvalidation(distributionId, "v1", region, s3Bucket);
      } else {
        await doInvalidation(distributionId, urlPrefix, region, s3Bucket);
      }
      console.log("doInvalidation completed");
    }
  } catch (err) {
    console.error("Error", err);
    throw err;
  }
};

module.exports = {
  run,
};
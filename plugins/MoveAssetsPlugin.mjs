import fs from 'fs';
import path from 'path';

export class MoveAssetsPlugin {
  constructor(options) {
    this.options = options;
  }

  apply(compiler) {
    const { appAssetsPath, patterns } = this.options;

    compiler.hooks.afterEmit.tapPromise('MoveAssetsPlugin', async (compilation) => {
      const outputPath = compilation.outputOptions.path;
      const assets = Object.keys(compilation.assets);

      for (const assetName of assets) {
        // Skip if asset matches any optional pattern
        const isOptional = patterns.some(pattern => {
          if (pattern instanceof RegExp) return pattern.test(assetName);
          return assetName.includes(pattern);
        });

        if (isOptional) continue;

        const originalPath = path.join(outputPath, assetName);

        // Check if the file exists in the default output path
        if (fs.existsSync(originalPath)) {
          const targetPath = path.join(appAssetsPath, assetName);

          // Ensure target directory exists
          await fs.promises.mkdir(path.dirname(targetPath), { recursive: true });

          // Copy file to target path
          await fs.promises.copyFile(originalPath, targetPath);
        }
      }
    });
  }
}
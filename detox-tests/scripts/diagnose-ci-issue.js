#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔍 Detox CI Issue Diagnostic Tool');
console.log('================================');

// Check environment
console.log('\n📋 Environment Information:');
console.log('Node version:', process.version);
console.log('Platform:', process.platform);
console.log('Architecture:', process.arch);
console.log('CI Environment:', process.env.CI ? 'Yes' : 'No');
console.log('GitHub Actions:', process.env.GITHUB_ACTIONS ? 'Yes' : 'No');

// Check if we're in CI
const isCI = process.env.CI || process.env.GITHUB_ACTIONS;
console.log('Running in CI:', isCI ? 'Yes' : 'No');

// Check Detox configuration
console.log('\n🔧 Detox Configuration:');
const detoxConfigPath = path.join(process.cwd(), '.detoxrc.js');
if (fs.existsSync(detoxConfigPath)) {
  console.log('✅ .detoxrc.js found');
  const config = require(detoxConfigPath);
  console.log('Available configurations:', Object.keys(config.configurations || {}));
  
  // Check which configuration is likely being used in CI
  if (config.configurations['android.emu.ci.debug']) {
    console.log('🎯 CI configuration found: android.emu.ci.debug');
    console.log('CI Device:', JSON.stringify(config.devices.ciEmulator, null, 2));
    console.log('CI App:', JSON.stringify(config.apps['android.debug'], null, 2));
  }
} else {
  console.log('❌ .detoxrc.js not found');
}

// Check test files
console.log('\n📁 Test Files:');
const testDir = path.join(process.cwd(), 'detox-tests', 'e2e');
if (fs.existsSync(testDir)) {
  const testFiles = fs.readdirSync(testDir).filter(f => f.endsWith('.test.ts'));
  console.log('Test files found:', testFiles);
} else {
  console.log('❌ Test directory not found');
}

// Check test IDs
console.log('\n🏷️  Test IDs:');
const testIdsPath = path.join(process.cwd(), 'src', 'utility', 'test', 'TestUtils.bs.js');
if (fs.existsSync(testIdsPath)) {
  console.log('✅ TestUtils.bs.js found');
  const testIdsContent = fs.readFileSync(testIdsPath, 'utf8');
  const testIdMatches = testIdsContent.match(/var \w+TestId = "([^"]+)"/g);
  if (testIdMatches) {
    console.log('Test IDs found:');
    testIdMatches.forEach(match => {
      const [, testId] = match.match(/var (\w+TestId) = "([^"]+)"/);
      console.log(`  - ${testId}: "${match.split('"')[1]}"`);
    });
  }
} else {
  console.log('❌ TestUtils.bs.js not found');
}

// Check artifacts directory
console.log('\n📸 Artifacts:');
const artifactsDir = path.join(process.cwd(), 'artifacts');
if (fs.existsSync(artifactsDir)) {
  const artifacts = fs.readdirSync(artifactsDir);
  console.log('Recent artifact directories:', artifacts.slice(-5));
  
  // Check for screenshots in latest artifact
  if (artifacts.length > 0) {
    const latestArtifact = artifacts[artifacts.length - 1];
    const latestArtifactPath = path.join(artifactsDir, latestArtifact);
    if (fs.existsSync(latestArtifactPath)) {
      const screenshots = fs.readdirSync(latestArtifactPath).filter(f => f.endsWith('.png'));
      console.log(`Screenshots in ${latestArtifact}:`, screenshots);
    }
  }
} else {
  console.log('❌ Artifacts directory not found');
}

// Recommendations
console.log('\n💡 Recommendations:');
console.log('1. Run the debug test: npm run detox:test:debug');
console.log('2. Check screenshots in artifacts directory');
console.log('3. Verify emulator configuration matches between local and CI');
console.log('4. Check if app builds correctly in CI environment');
console.log('5. Verify test IDs are correctly set in the app components');

// Generate debug command
console.log('\n🚀 Debug Commands:');
console.log('Run debug test:');
console.log('  detox test detox-tests/e2e/card-flow-e2e-debug.test.ts --configuration android.emu.ci.debug');
console.log('\nRun with verbose logging:');
console.log('  detox test detox-tests/e2e/card-flow-e2e-debug.test.ts --configuration android.emu.ci.debug --loglevel verbose');

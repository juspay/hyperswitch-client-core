#  Security Practices Documentation

## 1. Overview
The purpose is to strengthen secret detection, improve configuration accuracy, and ensure all sensitive data (like API keys and tokens) are securely managed and never committed to the codebase.

---

## 2. GitLeaks Integration
[GitLeaks](https://github.com/gitleaks/gitleaks) is an open-source tool used to detect and prevent hardcoded secrets such as:
- API keys  
- Access tokens  
- Passwords  
- Private credentials  

It scans commits, branches, and repository files using **regex-based pattern matching**.

---

## 3. Enhanced GitLeaks Configuration
The `.gitleaks.toml` file has been improved to:
- Add more specific **secret detection patterns** for Juspay keys and payment industry credentials  
- Include **custom rules** for common API keys and certificates  
- Update **allowlists** to reduce false positives  
- Extend the **default GitLeaks rules** with additional high-sensitivity patterns  

###  Custom Rules Added
Below are the new detection rules implemented:

```toml
[[rules]]
id = "juspay-api-key"
description = "Juspay API key (publishable or secret) detected"
regex = '''(?i)(secret_key|publishable_key)\s*=\s*["']?[A-Za-z0-9_\-]{16,}["']?'''
tags = ["juspay", "api", "key"]

[[rules]]
id = "netcetera-certificate"
description = "Netcetera certificate detected"
regex = '''(?i)(nca_root_certificate|netcetera_cert|netcetera_private_key).*'''
tags = ["certificate", "netcetera", "security"]

[[rules]]
id = "aws-secret-access-key"
description = "AWS Secret Access Key detected"
regex = '''(?i)aws(.{0,20})?(secret|access)?(.{0,20})?['|"]([0-9a-zA-Z/+]{40})['|"]'''
tags = ["aws", "key"]

[[rules]]
id = "razorpay-api-key"
description = "Razorpay API Key detected"
regex = '''rzp_(test|live)_[0-9a-zA-Z]{24}'''
tags = ["razorpay", "api", "key"]

[[rules]]
id = "google-api-key"
description = "Google API Key detected"
regex = '''AIza[0-9A-Za-z\-_]{35}'''
tags = ["google", "api", "key"]

[[rules]]
id = "twilio-api-key"
description = "Twilio API Key detected"
regex = '''SK[0-9a-fA-F]{32}'''
tags = ["twilio", "api", "key"]

[[rules]]
id = "github-personal-access-token"
description = "GitHub Personal Access Token detected"
regex = '''ghp_[0-9a-zA-Z]{36}'''
tags = ["github", "token"]

[[rules]]
id = "generic-bearer-token"
description = "Generic Bearer Token detected"
regex = '''Bearer\s+[A-Za-z0-9\-._~+/]+=*'''
tags = ["token", "bearer", "auth"]
```

---

## 4. Enhanced Allowlists
To avoid false positives during scans, new **allowlists** have been defined for specific directories and file types.

```toml
[[allowlists]]
description = "Ignore all .env files"
paths = ['''\.env''']

[[allowlists]]
description = "Ignore .p12 files in ThreeDS SDK xcframework"
paths = [
    "ios/frameworkgen/3ds/Frameworks/ThreeDS_SDK.xcframework",
    "ios/build/Build/Products/Debug-iphonesimulator/hyperswitch.app/Frameworks/ThreeDS_SDK.framework",
    "ios/build/Build/Products/Debug-iphonesimulator/XCFrameworkIntermediates/react-native-hyperswitch-netcetera-3ds/ThreeDS_SDK.framework"
]
regexes = ["(^|/).*\.p12$"]

[[allowlists]]
description = "Ignore Cardinal JFrog in Android"
commits = [
    "00210e92b02c166825ceae8882dad79dc0149b2b",
    "84f22db3afd94b7094940d0759c89e3477772bf7"
]
regexes = [
    "/.*DAUQKXLDPDx6NYRkqrgFLRc3qDrayg6rrCb.*/",
    "/.*_e.minKey=_e.mergeU=void.*/"
]

[[allowlists]]
description = "Ignore .bundle files in iOS"
paths = [
    "hyperswitchSDK/Core/Resources",
    "hyperswitch/hyperWrapper/Resources",
]
regexes = ["hyperswitch.bundle"]
```

---

## 5. Package Script Addition
A new **npm script** was added to make GitLeaks easy to run locally.

### In `package.json`:
```json
"scripts": {
  ...
  "lint:secrets": "gitleaks detect --source . --no-banner --verbose"
}
```

This allows developers to run:
```bash
npm run lint:secrets
# or
yarn lint:secrets
```

to perform a full secret scan before committing code.

---

## 6. Secret Scanning for Environment Variables
The repository ensures `.env` and similar files containing sensitive data are **excluded from commits** via `.gitignore`.

Developers should:
- Always store secrets in `.env` files  
- Never commit these files to Git  
- Verify `.env` is correctly ignored before pushing changes  

Example `.env`:
```
SECRET_KEY=xxxxxxxxxxxxxxxxxxxx
PUBLISHABLE_KEY=xxxxxxxxxxxxxxxxxxxx
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

GitLeaks rules are designed to detect any accidental exposure of `.env` variables even if they’re not ignored.

---

## 7. Running a Local Secret Scan
To check for exposed credentials in your code:

```bash
npm run lint:secrets
```

Output Example:
```
INFO[0000] scanning commits...                          
INFO[0002] scan completed (0 leaks found)
```

If leaks are found, review the file, remove or rotate the secret, and re-run the scan until clean.

---

## 8. Developer Guidelines
All contributors are required to follow these secure coding practices:
1. Run a GitLeaks scan before committing.
2. Never hardcode credentials, tokens, or passwords.
3. Use environment variables for sensitive configurations.
4. Keep the `.gitleaks.toml` file up-to-date if new integrations (e.g. new APIs or SDKs) are added.
5. Review scan results carefully before creating pull requests.

---

## 9. Future Enhancements (CI/CD)
GitLeaks can be integrated into **GitHub Actions** to automatically run during pull requests or merges.

Example GitHub Action configuration:

```yaml
- name: Run GitLeaks Scan
  uses: zricethezav/gitleaks-action@v2
  with:
    args: detect --source . --no-banner --verbose
```

This step ensures all PRs are automatically checked for leaks in CI pipelines.

---

## 10. Benefits of This Implementation
-  Strengthens repository security posture  
-  Prevents accidental leakage of API keys and credentials  
-  Increases coverage for payment-related secret detection  
-  Reduces false positives through refined allowlists  
-  Simplifies developer workflow with an npm command  
-  Encourages consistent security practices  

---

## 11. Maintenance
Maintainers should:
- Regularly update `.gitleaks.toml` to include new patterns.  
- Keep `.gitignore` synced with all `.env` and sensitive config files.  
- Review GitLeaks version updates and adjust regex patterns if required.  
- Audit secret scans during releases.





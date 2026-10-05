# macOS packages

Mac releases contain `R3.app` in `rCubed-VERSION-macOS-universal.zip`. The application includes its AIR runtime and contains native Intel (`x86_64`) and Apple Silicon (`arm64`) executables. Extract the archive and move `R3.app` into Applications.

Packages currently use ad hoc code signatures. Downloaded applications may require approval in macOS Privacy & Security. Trusted distribution requires an Apple Developer ID signature and notarization; release maintainers should complete that process before offering a notarized download.

## Build and release workflow

The Windows build continues to compile the fonts and platform-independent game SWF using AIR 32. The Mac workflow packages that same SWF with HARMAN AIR SDK **51.1.3.5**, which provides a universal runtime. The SDK archive is pinned by version and SHA-256 checksum.

The shared `macos-package.yml` workflow:

1. Downloads the SWF artifact from the Windows build.
2. Packages the game, icons and changelog into an application bundle.
3. Verifies that both the launcher and AIR runtime contain Intel and Apple Silicon code, signs the bundle and checks its signature.
4. Starts the native application for 15 seconds on both `macos-15-intel` and `macos-15` (Apple Silicon).
5. Adds the Mac ZIP to the existing draft release after both startup checks pass.

Both tag releases and manual releases call this workflow. The Check workflow also builds the Mac package on branch pushes and pull requests, without creating a release.

The startup checks catch missing runtimes, invalid signatures and early process exits. They do not replace playtesting, login checks or latency measurements. CI covers macOS 15 on both architectures.

Official releases retain the existing `BRANDING_SWC` and `SCORE_SAVE_SALT` secret requirements. Forks do not inherit these secrets; ordinary Check builds use the repository's development branding. If an AIR SDK license is required for the maintainer's use, provide the Base64-encoded `adt.lic` as `AIR_SDK_LICENSE_FILE`. It is installed on the packaging runner and is not included in the application archive.

## Package locally

Run these commands on macOS with Java 11 or newer and a compiled `R3Air.swf`. The normal development build creates `bin/develop/R3Air.swf`; a release build creates `bin/release/R3Air.swf`.

Downloading the SDK accepts the [HARMAN AIR SDK license agreement](https://airsdk.harman.com/assets/pdfs/HARMAN%20AIR%20SDK%20License%20Agreement.pdf).

```sh
bash scripts/setup-macos-sdk.sh "$PWD/../air-sdk-macos"
bash scripts/package-macos.sh "$PWD/../air-sdk-macos" bin/develop/R3Air.swf 0.0.0 dist/macos
ditto -x -k dist/macos/rCubed-0.0.0-macOS-universal.zip dist/macos/app
bash scripts/smoke-test-macos.sh dist/macos/app/R3.app
```

Use the release SWF and its numeric version when preparing a release package. Keep official branding and score-saving settings consistent with the Windows package.

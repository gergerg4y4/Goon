# Build JailbreakLab from an iPhone

1. Create a GitHub repository (private is fine).
2. Upload all contents of this JailbreakLab folder to the repository root, including `.github/workflows/build-unsigned-ipa.yml` (GitHub web UI can make uploading directories awkward; use a Git client or web editor).
3. Open repository > Actions > Build unsigned JailbreakLab IPA > Run workflow (or push to main).
4. When the run succeeds, open the run and download the JailbreakLab-unsigned.ipa artifact.
5. Import the unsigned IPA into Feather/ESign and sign it with your own valid, device-compatible certificate and provisioning profile, then install.

Never upload signing private keys or certificates to a public repository. An unsigned IPA cannot install directly. Builds are not verified in Xcode by this package's author; review Actions logs if compilation fails.

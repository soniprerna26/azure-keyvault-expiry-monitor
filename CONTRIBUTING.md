# Contributing

Suggestions and improvements are welcome.

1. Fork the repository and create a branch: `git checkout -b feature/my-change`
2. Keep the script read-only with respect to Key Vault content.
3. Never commit credentials, tenant IDs, subscription IDs or real vault names.
4. Run the tests: `Invoke-Pester -Path .\tests`
5. Update `CHANGELOG.md` and the relevant documentation.
6. Open a pull request describing the change and how you tested it.

Report bugs through GitHub Issues with the PowerShell version, Az module version and the (redacted) error output.

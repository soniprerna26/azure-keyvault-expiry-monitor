# Security Considerations

## What the script touches

| Data | Handled? |
|---|---|
| Secret names and expiry dates | Read |
| Secret **values** | Not read or displayed |
| Certificate names and expiry dates | Read |
| Private keys | Not accessed |
| SMTP password | Entered at runtime, held as a `PSCredential` (SecureString) in memory only |

## Controls

1. **No hard-coded credentials.** `Get-Credential` prompts at runtime. Do not replace this with a plain-text password variable.
2. **Least privilege.** The identity needs read access to list secrets and certificates only. Do not give it Set, Delete, Purge or key permissions.
3. **Encrypted transport.** `-UseSsl` on port 587 enables STARTTLS. Do not use port 25 over the internet.
4. **App passwords.** For Gmail, an app password limits exposure compared with the main account password and can be revoked independently.
5. **Source control hygiene.** `.gitignore` excludes `*.pfx`, `*.pem`, `*.key`, `*.env`, credential exports and local config files.
6. **Public repository checks before pushing.** Search your history for email addresses, vault names you do not want public, subscription IDs and tenant IDs.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Alert email contains item names | Names should not themselves be sensitive; avoid putting values in the message |
| Mailbox compromise exposes alerts | Use a dedicated alerts mailbox with MFA |
| Overprivileged automation identity | Use a managed identity with a narrowly scoped role |
| Alerts ignored (alert fatigue) | Move to a daily digest and route to a monitored channel |
| `Send-MailMessage` is obsolete | Migrate to Microsoft Graph or Azure Communication Services (see roadmap) |

## Unattended execution

When scheduling, avoid interactive prompts:

* Use an **Azure Automation credential asset** or a managed identity.
* Or store the SMTP app password as a secret in a *separate* management Key Vault and read it at runtime.
* Never save a credential to a file with `Export-Clixml` on a shared machine. That file is protected only for the same user and machine, and is still sensitive.

## Complementary native controls

Azure also offers native Key Vault near-expiry events through Event Grid and Azure Monitor alerting. This script is a lightweight, transparent alternative that works with any SMTP provider and is easy to audit.

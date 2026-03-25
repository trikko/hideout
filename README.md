# Hideout

Hideout is a minimal and secure desktop application for file encryption and decryption, powered by [GnuPG](https://gnupg.org/).

![Hideout Screenshot](hideout_screenshot.png)

## Features

- **Simple UI**: Drag and drop files to encrypt or decrypt.
- **Secure**: Uses GPG symmetric encryption. Passphrases are handled securely.
- **Multi-language**: Supported languages: English, Italian, French, Spanish, German, and Portuguese (BR).

## Download  
[![Get it on FlatHub](https://flathub.org/api/badge?locale=en)](https://flathub.org/en/apps/it.andreafontana.hideout)

## Build (system prerequisites)

- **GnuPG**: You must have `gpg` installed and available in your `PATH`.
- **GTK4 & Libadwaita**: Required for the graphical interface.
- **D compiler**: Check the official [dlang website](https://dlang.org/download.html) or download it from your distribution package manager.

## How to Build

```bash
dub run
```

## Security Note

Hideout uses GPG's symmetric encryption. The passphrase is used to derive a key for encryption. Always use a strong passphrase.

## License

MIT

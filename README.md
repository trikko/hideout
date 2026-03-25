# Hideout

Hideout is a minimal and secure desktop application for file encryption and decryption, powered by [GnuPG](https://gnupg.org/).

![Hideout Screenshot](hideout_screenshot.png)

## Features

- **Simple UI**: Drag and drop files to encrypt or decrypt.
- **Secure**: Uses GPG symmetric encryption. Passphrases are handled securely.
- **Multi-language**: Supported languages: English, Italian, French, Spanish, German, and Portuguese (BR).

## Download  
<a href="https://flathub.org/en/apps/it.andreafontana.hideout"><img src="https://flathub.org/api/badge?locale=en" height="60"></a>
<a href="https://snapcraft.io/hideout"><img src="https://snapcraft.io/en/dark/install.svg" height="60"></a>

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

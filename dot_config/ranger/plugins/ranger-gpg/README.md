# ranger-gpg
&nbsp;&nbsp;&nbsp;&nbsp;Ranger functions for encrypting and decrypting files and directories using gpg keys.

![ranger-gpg](assets/ex.gif)

## Requirements
&nbsp;&nbsp;&nbsp;&nbsp;The default recipient must be set in the `DEFAULT_RECIPIENT` environment variable. I suggest the variable be set in one of you shell config files (eg. `zshenv` or `bashenv`).

```
export DEFAULT_RECIPIENT="email@email.com"
```

## Usage
**Encryption**

&nbsp;&nbsp;&nbsp;&nbsp;Call `:encrypt` to encrypt with the default-key

**Decryption**

&nbsp;&nbsp;&nbsp;&nbsp;Call `:decrypt` to decrypt with the available secret key. If the secret key is not available the command will fail

## Installation
```
git clone https://gitlab.com/Ragnyll/ranger-gpg.git
cd ranger-gpg
pip install python-gnupg
make install
```

## Uninstall
```
make uninstall
```

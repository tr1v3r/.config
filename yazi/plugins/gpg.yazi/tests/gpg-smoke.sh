#!/bin/sh
set -eu

PLUGIN_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
YAZI_DIR=$(CDPATH='' cd -- "$PLUGIN_DIR/../.." && pwd)
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/yazi-gpg-test.XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM

export GNUPGHOME="$WORK_DIR/gnupg"
mkdir -m 700 "$GNUPGHOME"

gpg_test() {
	gpg --batch --no-tty "$@"
}

gpg_test \
	--passphrase "" \
	--quick-generate-key \
	"Yazi GPG Signer Test <yazi-gpg-signer@example.invalid>" \
	ed25519 cert 1d

SIGNER_FINGERPRINT=$(
	gpg_test --with-colons --list-secret-keys yazi-gpg-signer@example.invalid |
		awk -F: '$1 == "fpr" { print $10; exit }'
)
test "${#SIGNER_FINGERPRINT}" -eq 40

gpg_test \
	--passphrase "" \
	--quick-add-key "$SIGNER_FINGERPRINT" \
	ed25519 sign 1d
gpg_test \
	--passphrase "" \
	--quick-add-key "$SIGNER_FINGERPRINT" \
	cv25519 encrypt 1d

gpg_test \
	--passphrase "" \
	--quick-generate-key \
	"Yazi GPG Recipient Test <yazi-gpg-recipient@example.invalid>" \
	ed25519 cert 1d

RECIPIENT_FINGERPRINT=$(
	gpg_test --with-colons --list-secret-keys yazi-gpg-recipient@example.invalid |
		awk -F: '$1 == "fpr" { print $10; exit }'
)
test "${#RECIPIENT_FINGERPRINT}" -eq 40

gpg_test \
	--passphrase "" \
	--quick-add-key "$RECIPIENT_FINGERPRINT" \
	cv25519 encrypt 1d

gpg_test --yes --delete-secret-keys "$RECIPIENT_FINGERPRINT"
if gpg_test --with-colons --list-secret-keys "$RECIPIENT_FINGERPRINT" >/dev/null 2>&1; then
	echo "configured recipient unexpectedly still has a secret key" >&2
	exit 1
fi

cp "$YAZI_DIR/keymap.toml" "$WORK_DIR/plain.toml"
gpg_test \
	--status-fd 1 \
	--local-user "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/plain.toml.sig" \
	--detach-sign -- "$WORK_DIR/plain.toml" \
	>"$WORK_DIR/detached-sign.status"
grep -Fq "[GNUPG:] SIG_CREATED" "$WORK_DIR/detached-sign.status"

gpg_test \
	--no-auto-key-retrieve \
	--status-fd 1 \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--verify -- "$WORK_DIR/plain.toml.sig" "$WORK_DIR/plain.toml" \
	>"$WORK_DIR/detached-verify.status"
grep -Fq "[GNUPG:] VALIDSIG" "$WORK_DIR/detached-verify.status"

if gpg_test \
	--no-auto-key-retrieve \
	--status-fd 1 \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--verify -- "$WORK_DIR/plain.toml.sig" "$YAZI_DIR/init.lua" \
	>"$WORK_DIR/detached-invalid.status" 2>"$WORK_DIR/detached-invalid.err"
then
	echo "detached signature unexpectedly verified against another file" >&2
	exit 1
fi

gpg_test \
	--no-auto-key-locate \
	--trust-model always \
	--status-fd 1 \
	--local-user "$SIGNER_FINGERPRINT" \
	--recipient "$RECIPIENT_FINGERPRINT" \
	--recipient "$SIGNER_FINGERPRINT" \
	--set-filename plain.toml \
	--output "$WORK_DIR/plain.toml.gpg" \
	--sign --encrypt -- "$WORK_DIR/plain.toml" \
	>"$WORK_DIR/encrypt.status"
grep -Fq "[GNUPG:] SIG_CREATED" "$WORK_DIR/encrypt.status"

gpg_test \
	--no-auto-key-retrieve \
	--status-fd 1 \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/plain.restored.toml" \
	--decrypt -- "$WORK_DIR/plain.toml.gpg" \
	>"$WORK_DIR/decrypt.status"
grep -Fq "[GNUPG:] DECRYPTION_OKAY" "$WORK_DIR/decrypt.status"
grep -Fq "[GNUPG:] VALIDSIG" "$WORK_DIR/decrypt.status"
grep -Fq " plain.toml" "$WORK_DIR/decrypt.status"
cmp "$WORK_DIR/plain.toml" "$WORK_DIR/plain.restored.toml"

gpg_test \
	--no-auto-key-retrieve \
	--status-fd 2 \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--decrypt -- "$WORK_DIR/plain.toml.gpg" \
	>/dev/null 2>"$WORK_DIR/verify.status"
grep -Fq "[GNUPG:] DECRYPTION_OKAY" "$WORK_DIR/verify.status"
grep -Fq "[GNUPG:] VALIDSIG" "$WORK_DIR/verify.status"

mkdir "$WORK_DIR/batch"
cp "$YAZI_DIR/keymap.toml" "$WORK_DIR/batch/one"
cp "$YAZI_DIR/init.lua" "$WORK_DIR/batch/two"
for name in one two; do
	cp "$WORK_DIR/batch/$name" "$WORK_DIR/batch/$name.expected"
	gpg_test \
		--no-auto-key-locate \
		--trust-model always \
		--local-user "$SIGNER_FINGERPRINT" \
		--recipient "$RECIPIENT_FINGERPRINT" \
		--recipient "$SIGNER_FINGERPRINT" \
		--set-filename "$name" \
		--output "$WORK_DIR/batch/$name.gpg" \
		--sign --encrypt -- "$WORK_DIR/batch/$name"
	rm "$WORK_DIR/batch/$name"
done

for name in one two; do
	gpg_test \
		--no-auto-key-retrieve \
		--status-fd 1 \
		--assert-signer "$SIGNER_FINGERPRINT" \
		--output "$WORK_DIR/batch/$name" \
		--decrypt -- "$WORK_DIR/batch/$name.gpg" \
		>"$WORK_DIR/batch/$name.decrypt.status"
	grep -Fq "[GNUPG:] DECRYPTION_OKAY" "$WORK_DIR/batch/$name.decrypt.status"
	grep -Fq "[GNUPG:] VALIDSIG" "$WORK_DIR/batch/$name.decrypt.status"
	cmp "$WORK_DIR/batch/$name.expected" "$WORK_DIR/batch/$name"
done

: >"$WORK_DIR/empty"
gpg_test \
	--no-auto-key-locate \
	--trust-model always \
	--local-user "$SIGNER_FINGERPRINT" \
	--recipient "$RECIPIENT_FINGERPRINT" \
	--recipient "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/empty.gpg" \
	--sign --encrypt -- "$WORK_DIR/empty"
gpg_test \
	--no-auto-key-retrieve \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/empty.restored" \
	--decrypt -- "$WORK_DIR/empty.gpg"
test -e "$WORK_DIR/empty.restored"
test ! -s "$WORK_DIR/empty.restored"

mkdir "$WORK_DIR/bundle"
cp "$YAZI_DIR/keymap.toml" "$WORK_DIR/bundle/keymap.toml"
cp "$YAZI_DIR/init.lua" "$WORK_DIR/bundle/init.lua"
tar -czf "$WORK_DIR/yazi-gpg-archive-v1.tar.gz" -C "$WORK_DIR" -- bundle

gpg_test \
	--no-auto-key-locate \
	--trust-model always \
	--status-fd 1 \
	--local-user "$SIGNER_FINGERPRINT" \
	--recipient "$RECIPIENT_FINGERPRINT" \
	--recipient "$SIGNER_FINGERPRINT" \
	--set-filename yazi-gpg-archive-v1.tar.gz \
	--output "$WORK_DIR/bundle.tar.gz.gpg" \
	--sign --encrypt -- "$WORK_DIR/yazi-gpg-archive-v1.tar.gz" \
	>"$WORK_DIR/bundle-encrypt.status"

gpg_test \
	--no-auto-key-retrieve \
	--status-fd 1 \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/bundle.restored.tar.gz" \
	--decrypt -- "$WORK_DIR/bundle.tar.gz.gpg" \
	>"$WORK_DIR/bundle-decrypt.status"
grep -Fq "[GNUPG:] DECRYPTION_OKAY" "$WORK_DIR/bundle-decrypt.status"
grep -Fq "[GNUPG:] VALIDSIG" "$WORK_DIR/bundle-decrypt.status"
grep -Fq " yazi-gpg-archive-v1.tar.gz" "$WORK_DIR/bundle-decrypt.status"

mkdir "$WORK_DIR/extracted"
tar -xzf "$WORK_DIR/bundle.restored.tar.gz" -C "$WORK_DIR/extracted"
cmp "$WORK_DIR/bundle/keymap.toml" "$WORK_DIR/extracted/bundle/keymap.toml"
cmp "$WORK_DIR/bundle/init.lua" "$WORK_DIR/extracted/bundle/init.lua"

gpg_test \
	--no-auto-key-locate \
	--trust-model always \
	--recipient "$RECIPIENT_FINGERPRINT" \
	--recipient "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/legacy.gpg" \
	--encrypt -- "$WORK_DIR/plain.toml"

if gpg_test \
	--no-auto-key-retrieve \
	--status-fd 1 \
	--assert-signer "$SIGNER_FINGERPRINT" \
	--output "$WORK_DIR/legacy.strict.out" \
	--decrypt -- "$WORK_DIR/legacy.gpg" \
	>"$WORK_DIR/legacy-strict.status" 2>"$WORK_DIR/legacy-strict.err"
then
	echo "unsigned ciphertext unexpectedly passed strict verification" >&2
	exit 1
fi
grep -Fq "[GNUPG:] DECRYPTION_OKAY" "$WORK_DIR/legacy-strict.status"
if grep -Fq "[GNUPG:] VALIDSIG" "$WORK_DIR/legacy-strict.status"; then
	echo "unsigned ciphertext unexpectedly reported a valid signature" >&2
	exit 1
fi

gpg_test \
	--no-auto-key-retrieve \
	--output "$WORK_DIR/legacy.out" \
	--decrypt -- "$WORK_DIR/legacy.gpg"
cmp "$WORK_DIR/plain.toml" "$WORK_DIR/legacy.out"

echo "PASS: detached signatures, batch decrypt, and dual-recipient fallback"

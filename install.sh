#!/bin/sh
# Install concept-scanner for the current user, on macOS or Linux. Nothing is
# written outside your home folder apart from a temporary download folder that
# is removed when the script ends, and nothing needs administrator rights.
#
#   curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Obviously-Not/concept-scanner-public/main/install.sh | sh
#
# Options (after `sh -s --` when piped, as in `... | sh -s -- --uninstall`):
#   --no-modify-path   leave shell startup files alone, and print the line to add
#   --uninstall        remove what this script installs
#
# It runs nothing it downloaded until the release's list of checksums has been
# checked against the publisher's signature (with OpenSSL 3, or with bc where
# that is missing, as on a Mac out of the box), the program against that list,
# and, on macOS, the program's Apple Developer ID signature.
#
# Running it again installs the latest release over the copy you have, which is
# also how a copy from before `concept-scanner update` existed is brought up to
# date. After that, `concept-scanner update` checks and installs new releases.
#
# The whole script is functions, and the last line calls one of them, so a
# download cut off part way runs nothing.

# Where releases are downloaded from. Tests replace this one line with a local
# server; nothing at run time changes it.
CS_RELEASES='https://github.com/Obviously-Not/concept-scanner-public/releases/latest/download'

# The keys that sign each release's checksums.txt, as checksums.txt.sig:
# Ed25519, base64, comma separated, the same two concept-scanner carries to
# check its own updates. A release whose signature none of them verifies installs
# nothing. Tests replace this one line with a key of their own.
CS_SIGNING_KEYS='vkbGnJckdjq0FiOw6kMHNDWqme3U16YiTImqvCK2+qQ=,9XAYom1DCpn/qeRU2IMVMyR4Jrfzdz8COWk09mP6J/Y='

# What codesign must find on the downloaded program on macOS: a Developer ID
# Application signature that Apple issued to this publisher's team. Tests replace
# this one line.
CS_APPLE_REQUIREMENT='anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = "WSG9UQ34A7"'

# A known answer every signature checker must give before its answer about a
# release is believed: RFC 8032's second Ed25519 test vector (the one-byte
# message "r") verifies, and the same key with a signature whose R is the
# identity point and whose S is zero does not.
CS_TEST_KEY='PUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw='
CS_TEST_SIG='kqAJqfDUyrhyDoILX2QlQKKye1QWUD+Ps3YiI+vbadoIWsHkPhWZbkWPNhPQ8R2MOHsurrQwKu6wDSkWErsMAA=='
CS_TEST_FORGED='AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=='

# The comment that marks each line this script adds to a shell startup file, so
# a rerun adds nothing and --uninstall removes exactly those lines.
CS_MARKER='# added by the concept-scanner installer'

cs_say() { printf '%s\n' "$*"; }
cs_err() { printf 'concept-scanner install: %s\n' "$*" >&2; }

cs_usage() {
	cs_say "Install concept-scanner for the current user, into ~/.local/bin."
	cs_say ""
	cs_say "  --no-modify-path   leave shell startup files alone, and print the line to add"
	cs_say "  --uninstall        remove what this script installs"
}

cs_paths() {
	cs_bin_dir="$HOME/.local/bin"
	cs_dest="$cs_bin_dir/concept-scanner"
	cs_dir="$HOME/.concept-scanner"
	cs_env="$cs_dir/env"
	cs_fish_file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/concept-scanner.fish"
	# The extraction cache, in the folder Go's os.UserCacheDir names: it
	# regenerates on the next scan and holds extractions of every repository
	# scanned, so uninstalling removes it.
	case "$(uname -s)" in
	Darwin) cs_cache="$HOME/Library/Caches/concept-scanner" ;;
	*)
		case "${XDG_CACHE_HOME:-}" in
		/*) cs_cache="$XDG_CACHE_HOME/concept-scanner" ;;
		*) cs_cache="$HOME/.cache/concept-scanner" ;;
		esac
		;;
	esac
}

# cs_detect_asset prints the release file for this machine, named the way the
# release names it.
cs_detect_asset() {
	cs_os=$(uname -s)
	cs_arch=$(uname -m)
	case "$cs_os" in
	Darwin) cs_os=darwin ;;
	Linux) cs_os=linux ;;
	*)
		cs_err "no release binary is published for $cs_os. On Windows use install.ps1; elsewhere the container image runs it (see the README)."
		return 1
		;;
	esac
	case "$cs_arch" in
	x86_64 | amd64) cs_arch=amd64 ;;
	arm64 | aarch64) cs_arch=arm64 ;;
	*)
		cs_err "no release binary is published for $cs_arch."
		return 1
		;;
	esac
	# A shell running under Rosetta reports x86_64 on Apple silicon; install the
	# native build. -i because the name is absent on Intel Macs, where -n alone
	# fails.
	if [ "$cs_os" = darwin ] && [ "$cs_arch" = amd64 ] && [ "$(sysctl -in sysctl.proc_translated 2>/dev/null)" = 1 ]; then
		cs_arch=arm64
	fi
	printf 'concept-scanner-%s-%s\n' "$cs_os" "$cs_arch"
}

cs_fetch() {
	if command -v curl >/dev/null 2>&1; then
		curl --proto '=https' --tlsv1.2 -fsSL --retry 2 -o "$2" "$1"
	elif command -v wget >/dev/null 2>&1; then
		wget --https-only -q -O "$2" "$1"
	else
		cs_err "this needs curl or wget to download the release."
		return 1
	fi
}

cs_sha256() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | cut -d ' ' -f 1
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | cut -d ' ' -f 1
	else
		cs_err "this needs sha256sum or shasum to check the download."
		return 1
	fi
}

cs_sha512() {
	if command -v sha512sum >/dev/null 2>&1; then
		sha512sum | cut -d ' ' -f 1
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 512 | cut -d ' ' -f 1
	elif command -v openssl >/dev/null 2>&1; then
		openssl dgst -sha512 | awk '{ print $NF }'
	else
		return 1
	fi
}

# cs_b64_bytes decodes base64 on stdin and prints its bytes as decimal numbers
# on one line. awk does it because base64(1) takes different flags on macOS and
# Linux.
cs_b64_bytes() {
	awk 'BEGIN { t = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" }
	{ s = s $0 }
	END {
		gsub(/[ \t\r]/, "", s)
		acc = 0; bits = 0; out = ""
		for (i = 1; i <= length(s); i++) {
			c = substr(s, i, 1)
			if (c == "=") break
			v = index(t, c) - 1
			if (v < 0) { print ""; exit }
			acc = acc * 64 + v; bits += 6
			if (bits >= 8) { bits -= 8; b = int(acc / 2 ^ bits); acc -= b * 2 ^ bits; out = out " " b }
		}
		print out
	}'
}

# cs_hex_bytes prints the bytes of the hex digest that starts its input.
cs_hex_bytes() {
	awk '{ h = tolower($1); out = ""
		for (i = 1; i < length(h); i += 2) {
			b = (index("0123456789abcdef", substr(h, i, 1)) - 1) * 16 + index("0123456789abcdef", substr(h, i + 1, 1)) - 1
			out = out " " b
		}
		print out
		exit }'
}

# cs_write_bytes writes the bytes its arguments give as decimal numbers. It is
# never called without one: printf would write a zero byte for none.
cs_write_bytes() {
	printf "$(printf '\\%03o' "$@")"
}

cs_count() { echo $#; }

cs_bc_array() {
	cs_name=$1
	shift
	cs_i=0
	for cs_b in "$@"; do
		printf '%s[%d] = %s\n' "$cs_name" "$cs_i" "$cs_b"
		cs_i=$((cs_i + 1))
	done
}

# cs_bc_program prints a bc program that checks an Ed25519 signature (RFC 8032,
# as Go's crypto/ed25519 checks it) given the key, the signature and
# SHA-512(R || key || message) as byte arrays, and prints 1 when it verifies and
# 0 when it does not. It is written for bc as macOS, GNU and BusyBox ship it, so
# it uses no else, no && and no ||.
cs_bc_program() {
	cat <<'EOF'
scale = 0
p = 2 ^ 255 - 19
define md(a) {
	a = a % p
	if (a < 0) a = a + p
	return (a)
}
define pw(b, e) {
	auto r
	r = 1
	b = md(b)
	while (e > 0) {
		if (e % 2 == 1) r = (r * b) % p
		e = e / 2
		b = (b * b) % p
	}
	return (r)
}
/* the group order, the curve constant d, 2d, and a square root of -1 */
el = 2 ^ 252 + 27742317777372353535851937790883648493
ed = md(-121665 * pw(121666, p - 2))
e2 = (2 * ed) % p
sq = pw(2, (p - 1) / 4)
/* dec decodes the point whose y is y and whose x has parity s into dx; 0 when
   there is none */
define dec(y, s) {
	auto y2, u, v, v3, v7, x, c, w
	if (y >= p) return (0)
	y2 = (y * y) % p
	u = md(y2 - 1)
	v = md(ed * y2 + 1)
	v3 = (((v * v) % p) * v) % p
	v7 = (((v3 * v3) % p) * v) % p
	x = (((u * v3) % p) * pw((u * v7) % p, (p - 5) / 8)) % p
	c = (((v * x) % p) * x) % p
	w = 0
	if (c == u) w = 1
	if (w == 0) {
		if (c == md(0 - u)) {
			x = (x * sq) % p
			w = 1
		}
	}
	if (w == 0) return (0)
	if (x == 0) {
		if (s == 1) return (0)
	}
	if (x % 2 != s) x = p - x
	dx = x
	return (1)
}
/* pa adds two points in extended coordinates into rx, ry, rz, rt */
define pa(x1, y1, z1, t1, x2, y2, z2, t2) {
	auto a, b, c, k, e, f, g, h
	a = ((y1 - x1) * (y2 - x2)) % p
	b = ((y1 + x1) * (y2 + x2)) % p
	c = (((e2 * t1) % p) * t2) % p
	k = (2 * z1 * z2) % p
	e = b - a
	f = k - c
	g = k + c
	h = b + a
	rx = md(e * f)
	ry = md(g * h)
	rt = md(e * h)
	rz = md(f * g)
	return (0)
}
EOF
	cs_bc_array ka $cs_key_bytes
	cs_bc_array sg $cs_sig_bytes
	cs_bc_array hh $cs_hash_bytes
	cat <<'EOF'
ok = 1
/* the base point B, from y = 4/5 */
by = md(4 * pw(5, p - 2))
z = dec(by, 0)
bx = dx
bt = (bx * by) % p
/* the key A, negated */
ay = 0
for (i = 31; i >= 0; i--) ay = ay * 256 + ka[i]
sa = ay / 2 ^ 255
ay = ay % 2 ^ 255
if (dec(ay, sa) == 0) ok = 0
nx = md(0 - dx)
nt = (nx * ay) % p
rr = 0
for (i = 31; i >= 0; i--) rr = rr * 256 + sg[i]
s = 0
for (i = 63; i >= 32; i--) s = s * 256 + sg[i]
if (s >= el) ok = 0
k = 0
for (i = 63; i >= 0; i--) k = k * 256 + hh[i]
k = k % el
/* [s]B - [k]A, both scalars at once, with B - A precomputed */
z = pa(bx, by, 1, bt, nx, ay, 1, nt)
cx = rx
cy = ry
cz = rz
ct = rt
for (i = 0; i < 256; i++) {
	bs[i] = s % 2
	s = s / 2
	bk[i] = k % 2
	k = k / 2
}
qx = 0
qy = 1
qz = 1
qt = 0
for (i = 255; i >= 0; i--) {
	z = pa(qx, qy, qz, qt, qx, qy, qz, qt)
	qx = rx
	qy = ry
	qz = rz
	qt = rt
	c = bs[i] + 2 * bk[i]
	if (c == 1) z = pa(qx, qy, qz, qt, bx, by, 1, bt)
	if (c == 2) z = pa(qx, qy, qz, qt, nx, ay, 1, nt)
	if (c == 3) z = pa(qx, qy, qz, qt, cx, cy, cz, ct)
	if (c > 0) {
		qx = rx
		qy = ry
		qz = rz
		qt = rt
	}
}
/* it verifies when that point's encoding is the signature's R */
zi = pw(qz, p - 2)
x = (qx * zi) % p
y = (qy * zi) % p
v = 0
if (ok == 1) {
	if (y + (x % 2) * 2 ^ 255 == rr) v = 1
}
v
EOF
}

# cs_ed25519 KEY SIGFILE MSGFILE WORK succeeds when SIGFILE holds a base64
# Ed25519 signature by KEY over MSGFILE, checked with the program cs_verifier
# names, openssl or bc.
cs_ed25519() {
	cs_key_bytes=$(printf '%s\n' "$1" | cs_b64_bytes)
	cs_sig_bytes=$(cs_b64_bytes <"$2")
	[ "$(cs_count $cs_key_bytes)" = 32 ] || return 1
	[ "$(cs_count $cs_sig_bytes)" = 64 ] || return 1
	if [ "$cs_verifier" = openssl ]; then
		# The key as DER: the SubjectPublicKeyInfo prefix for Ed25519, then the key.
		cs_write_bytes 48 42 48 5 6 3 43 101 112 3 33 0 $cs_key_bytes >"$4/key.der"
		cs_write_bytes $cs_sig_bytes >"$4/sig.bin"
		openssl pkeyutl -verify -pubin -keyform DER -inkey "$4/key.der" -rawin -in "$3" -sigfile "$4/sig.bin" >/dev/null 2>&1
		return
	fi
	cs_r=$(echo $cs_sig_bytes | cut -d ' ' -f 1-32)
	cs_hash_bytes=$({ cs_write_bytes $cs_r $cs_key_bytes && cat "$3"; } | cs_sha512 | cs_hex_bytes) || return 1
	[ "$(cs_count $cs_hash_bytes)" = 64 ] || return 1
	cs_bc_program >"$4/verify.bc"
	# A setting in the environment can make bc refuse the program (-s) or set
	# its scale (-l), so neither reaches it.
	[ "$( (unset POSIXLY_CORRECT BC_ENV_ARGS && bc <"$4/verify.bc") 2>/dev/null)" = 1 ]
}

# cs_choose_verifier picks the first of OpenSSL 3 and bc that gives the known
# answers above, into cs_verifier; LibreSSL, which macOS ships as openssl, and
# OpenSSL 1.1 cannot check Ed25519 this way, so they fail the known answer and
# bc is tried. It fails when neither gives them.
cs_choose_verifier() {
	printf 'r' >"$1/test.msg"
	printf '%s\n' "$CS_TEST_SIG" >"$1/test.sig"
	printf '%s\n' "$CS_TEST_FORGED" >"$1/forged.sig"
	for cs_verifier in openssl bc; do
		command -v "$cs_verifier" >/dev/null 2>&1 || continue
		if cs_ed25519 "$CS_TEST_KEY" "$1/test.sig" "$1/test.msg" "$1" && ! cs_ed25519 "$CS_TEST_KEY" "$1/forged.sig" "$1/test.msg" "$1"; then
			return 0
		fi
	done
	cs_verifier=""
	return 1
}

# cs_signed succeeds when checksums.txt.sig in the folder it is given verifies
# checksums.txt there against one of the release keys.
cs_signed() {
	for cs_k in $(printf '%s\n' "$CS_SIGNING_KEYS" | tr ',' ' '); do
		if cs_ed25519 "$cs_k" "$1/checksums.txt.sig" "$1/checksums.txt" "$1"; then
			return 0
		fi
	done
	return 1
}

# cs_apple_signed succeeds on macOS when the file carries the publisher's
# Developer ID signature, which codesign, on every Mac, checks; elsewhere there
# is no such signature to check.
cs_apple_signed() {
	[ "$(uname -s)" = Darwin ] || return 0
	codesign --verify --strict -R "=$CS_APPLE_REQUIREMENT" "$1" >/dev/null 2>&1
}

cs_on_path() {
	case ":${PATH:-}:" in
	*":$cs_bin_dir:"*) return 0 ;;
	esac
	return 1
}

cs_write_env() {
	mkdir -p "$cs_dir"
	chmod 700 "$cs_dir"
	cat >"$cs_env" <<EOF
$CS_MARKER: puts $cs_bin_dir on PATH, once.
case ":\${PATH}:" in
*":$cs_bin_dir:"*) ;;
*) export PATH="$cs_bin_dir:\$PATH" ;;
esac
EOF
}

# cs_hook adds one marked line sourcing the env file to a startup file, unless
# it is there already.
cs_hook() {
	cs_rc=$1
	if [ -f "$cs_rc" ] && grep -qF "$CS_MARKER" "$cs_rc"; then
		return 0
	fi
	if [ -e "$cs_rc" ] && [ ! -w "$cs_rc" ]; then
		cs_unwritable="$cs_unwritable $cs_rc"
		return 0
	fi
	# Keep the file's last line intact if it has no final newline.
	if [ -s "$cs_rc" ] && [ -n "$(tail -c 1 "$cs_rc")" ]; then
		printf '\n' >>"$cs_rc"
	fi
	if printf 'if [ -f "%s" ]; then . "%s"; fi %s\n' "$cs_env" "$cs_env" "$CS_MARKER" >>"$cs_rc" 2>/dev/null; then
		cs_changed="$cs_changed $cs_rc"
	else
		cs_unwritable="$cs_unwritable $cs_rc"
	fi
}

cs_hook_fish() {
	mkdir -p "$(dirname "$cs_fish_file")"
	cat >"$cs_fish_file" <<EOF
$CS_MARKER: puts $cs_bin_dir on PATH, once.
if not contains -- '$cs_bin_dir' \$PATH
    set -gx PATH '$cs_bin_dir' \$PATH
end
EOF
	cs_changed="$cs_changed $cs_fish_file"
}

cs_hook_shells() {
	case "${SHELL:-}" in
	*/zsh) cs_hook "${ZDOTDIR:-$HOME}/.zshrc" ;;
	*/bash)
		# A new terminal tab starts bash as a non-login shell on Linux, which
		# reads .bashrc; macOS Terminal starts a login shell, which reads
		# .bash_profile, or .profile when there is none.
		cs_hook "$HOME/.bashrc"
		if [ -f "$HOME/.bash_profile" ]; then
			cs_hook "$HOME/.bash_profile"
		else
			cs_hook "$HOME/.profile"
		fi
		;;
	*/fish) cs_hook_fish ;;
	*) cs_hook "$HOME/.profile" ;;
	esac
}

cs_install() {
	cs_modify_path=$1
	cs_asset=$(cs_detect_asset) || return 1

	cs_tmp=$(mktemp -d 2>/dev/null || mktemp -d -t concept-scanner)
	trap 'rm -rf "$cs_tmp"' EXIT
	trap 'exit 1' INT TERM

	cs_say "Downloading $cs_asset ..."
	if ! cs_fetch "$CS_RELEASES/$cs_asset" "$cs_tmp/$cs_asset"; then
		cs_err "could not download $cs_asset, so nothing was installed."
		return 1
	fi
	if ! cs_fetch "$CS_RELEASES/checksums.txt" "$cs_tmp/checksums.txt"; then
		cs_err "could not download the release's checksums.txt, so nothing was installed."
		return 1
	fi
	if ! cs_fetch "$CS_RELEASES/checksums.txt.sig" "$cs_tmp/checksums.txt.sig"; then
		cs_err "could not download the release's checksums.txt.sig, so nothing was installed."
		return 1
	fi
	# The checksum below proves the download is the file the release lists; the
	# signature proves the list is the publisher's, which a checksum from the
	# same place cannot.
	if ! cs_choose_verifier "$cs_tmp"; then
		cs_err "checking the release's signature needs OpenSSL 3 or bc, and neither is here, so nothing was installed."
		cs_err "Install either one and run this again; or run the container image, which needs neither (see the README)."
		return 1
	fi
	if ! cs_signed "$cs_tmp"; then
		cs_err "the release's checksums.txt is not signed by the concept-scanner release key, so nothing was installed."
		cs_err "A proxy or a captive portal that answered with its own page is the usual cause; try another network."
		cs_err "If it happens on a network you trust, please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security"
		return 1
	fi
	cs_say "The release's signature verifies (checked with $cs_verifier)."
	cs_want=$(awk -v f="$cs_asset" '$2 == f { print $1; exit }' "$cs_tmp/checksums.txt")
	if [ -z "$cs_want" ]; then
		cs_err "the release's checksums.txt lists no $cs_asset, so nothing was installed."
		return 1
	fi
	cs_got=$(cs_sha256 "$cs_tmp/$cs_asset") || return 1
	if [ "$cs_got" != "$cs_want" ]; then
		cs_err "$cs_asset does not match its checksum, so nothing was installed."
		cs_err "A proxy or a captive portal that answered with its own page is the usual cause; try another network."
		cs_err "If it happens on a network you trust, please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security"
		return 1
	fi
	if ! cs_apple_signed "$cs_tmp/$cs_asset"; then
		cs_err "$cs_asset does not carry the publisher's Apple Developer ID signature, so nothing was installed."
		cs_err "Please report it privately: https://github.com/Obviously-Not/concept-scanner-public/security"
		return 1
	fi

	mkdir -p "$cs_bin_dir"
	cs_staged="$cs_bin_dir/.concept-scanner-install.$$"
	cp "$cs_tmp/$cs_asset" "$cs_staged"
	chmod 755 "$cs_staged"
	# Run the new copy before it replaces anything.
	if ! "$cs_staged" version >"$cs_tmp/version.txt" 2>&1; then
		rm -f "$cs_staged"
		cs_err "the downloaded program would not run here, so nothing was installed."
		return 1
	fi
	# A rename, never a write over the old file: a copy that is running is left
	# undisturbed.
	mv -f "$cs_staged" "$cs_dest"
	cs_say "Installed $(head -n 1 "$cs_tmp/version.txt") at $cs_dest"

	cs_changed=""
	cs_unwritable=""
	cs_was_on_path=0
	if cs_on_path; then
		cs_was_on_path=1
	elif [ "$cs_modify_path" = 1 ]; then
		cs_write_env
		cs_hook_shells
	fi

	if [ -n "$cs_changed" ]; then
		cs_say "Added $cs_bin_dir to your PATH in:$cs_changed"
		cs_say "Open a new terminal, or run this in the current one:"
		cs_say "  . \"$cs_env\""
	fi
	if [ "$cs_was_on_path" = 0 ] && { [ "$cs_modify_path" = 0 ] || [ -n "$cs_unwritable" ]; }; then
		[ -z "$cs_unwritable" ] || cs_say "Could not write:$cs_unwritable"
		cs_say "Add this line to your shell's startup file:"
		cs_say "  export PATH=\"$cs_bin_dir:\$PATH\""
	fi
	if [ "$cs_was_on_path" = 1 ]; then
		cs_found=$(command -v concept-scanner 2>/dev/null || true)
		if [ -n "$cs_found" ] && [ "$cs_found" != "$cs_dest" ]; then
			cs_say "Note: another concept-scanner comes first on your PATH, at $cs_found."
			cs_say "Remove it, or run this one as $cs_dest."
		fi
	fi
	if ! command -v ollama >/dev/null 2>&1; then
		cs_say "concept-scanner reads code with a model on this machine, through Ollama, which was not found on your PATH."
		cs_say "If it is not installed: https://ollama.com/download"
	fi
	cs_say "Next: concept-scanner scan ."
}

cs_uninstall() {
	for cs_rc in "${ZDOTDIR:-$HOME}/.zshrc" "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
		if [ -f "$cs_rc" ] && grep -qF "$CS_MARKER" "$cs_rc"; then
			cs_kept="$cs_rc.concept-scanner-uninstall.$$"
			grep -vF "$CS_MARKER" "$cs_rc" >"$cs_kept" || true
			# Written back in place, so the file keeps its owner and permissions.
			cat "$cs_kept" >"$cs_rc"
			rm -f "$cs_kept"
			cs_say "Removed the line it added to $cs_rc"
		fi
	done
	rm -f "$cs_fish_file" "$cs_dest" "$cs_env"
	rm -rf "$cs_cache"
	cs_say "Removed $cs_dest and the extraction cache, $cs_cache."
	# ~/.concept-scanner holds your scans, settings and saved keys, which are
	# yours to delete. It goes only when the PATH file was all it held.
	rmdir "$cs_dir" 2>/dev/null || true
	if [ -d "$cs_dir" ]; then
		cs_say "Kept $cs_dir: your scans, settings and any API keys you saved."
		cs_say "To delete them too: rm -rf \"$cs_dir\""
	fi
}

cs_main() {
	set -eu
	if [ -z "${HOME:-}" ]; then
		cs_err "HOME is not set, so there is nowhere to install."
		return 1
	fi
	cs_paths
	cs_modify=1
	for cs_arg in "$@"; do
		case "$cs_arg" in
		--uninstall)
			cs_uninstall
			return 0
			;;
		--no-modify-path) cs_modify=0 ;;
		-h | --help)
			cs_usage
			return 0
			;;
		*)
			cs_err "unknown option: $cs_arg (try --help)"
			return 1
			;;
		esac
	done
	cs_install "$cs_modify"
}

cs_main "$@" || exit 1

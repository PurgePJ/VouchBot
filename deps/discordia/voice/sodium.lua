return function(filename)

local ffi = require("ffi")
local success, lib = pcall(ffi.load, filename)
if not success then return error(lib) end

local new, string = ffi.new, ffi.string

ffi.cdef[[
const char *sodium_version_string(void);

size_t crypto_secretbox_keybytes(void);
size_t crypto_secretbox_noncebytes(void);
size_t crypto_secretbox_macbytes(void);
size_t crypto_secretbox_zerobytes(void);
size_t crypto_secretbox_boxzerobytes(void);

int crypto_secretbox_easy(
	unsigned char *c,
	const unsigned char *m,
	unsigned long long mlen,
	const unsigned char *n,
	const unsigned char *k
);

int crypto_secretbox_open_easy(
	unsigned char *m,
	const unsigned char *c,
	unsigned long long clen,
	const unsigned char *n,
	const unsigned char *k
);
]]

local function encrypt(decrypted, nonce, key)

	local decrypted_len = #decrypted
	local encrypted_len = decrypted_len + lib.crypto_secretbox_macbytes()

	local encrypted = new('unsigned char[?]', encrypted_len)

	if lib.crypto_secretbox_easy(encrypted, decrypted, decrypted_len, nonce, key) < 0 then
		return error('libsodium encryption failed')
	end

	return string(encrypted, encrypted_len)

end

local function decrypt(encrypted, nonce, key)

	local encrypted_len = #encrypted
	local decrypted_len = encrypted_len - lib.crypto_secretbox_macbytes()

	local decrypted = new('unsigned char[?]', decrypted_len)

	if lib.crypto_secretbox_open_easy(decrypted, encrypted, encrypted_len, nonce, key) < 0 then
		return error('libsodium decryption failed')
	end

	return string(decrypted, decrypted_len)

end

return {
	encrypt = encrypt,
	decrypt = decrypt,
}

end

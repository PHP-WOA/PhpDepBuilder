cd /d %~dp0
for %%i in (
argon2
freetype
gettext
icu4c
imap
libavif
libbzip2
libffi
libiconv
libjpeg
liblzma
libsodium
libtidy
libwebp
libxpm
libzstd
lmdb
mpir
nghttp2
oniguruma
openssl
pslib
pthreads
qdbm
sqlite3
wineditline
zlib
cyrus-sasl
glib
enchant
libpng
librdkafka
libssh2
curl
libxml2
libxslt
libzip
net-snmp
openldap
postgresql
) do (
setlocal
call components\%%i.cmd
endlocal
)
import leveldb
db = leveldb.LevelDB('./')

db.Delete(b'META:file://')
db.Delete(b'META:https://googleads.g.doubleclick.net')
db.Delete(b'META:https://localhost')
db.Delete(b'_https://googleads.g.doubleclick.net\0\x01experiment_seed_v2')
db.Delete(b'_https://localhost\0\x01CookieClickerSave.txt')
db.Delete(b'_file://\0\x01CookieClickerSaveTest.txt')
db.Delete(b'_file://\0\x01CookieClickerSave.txt')

import sqlite3
conn = sqlite3.connect("/var/kmediwell/kmediwell.db")
c = conn.cursor()
c.execute("PRAGMA table_info(Reservation)")
cols = [r[1] for r in c.fetchall()]
print("RefCode exists:", "RefCode" in cols)
print("Last 4 cols:", cols[-4:])
conn.close()

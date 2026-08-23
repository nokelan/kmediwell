import sqlite3, random, datetime

DB = '/home/ubuntu/kmediwell-api/kmediwell.db'
conn = sqlite3.connect(DB)
cur = conn.cursor()

treatments = [(1,'리쥬란힐러',350000),(2,'울쎄라',800000),(3,'써마지',900000),(4,'보톡스',150000),(5,'필러',250000)]
slot_times = [('09:00','10:30'),('11:00','12:30'),('14:00','15:30'),('16:00','17:30')]
names = ['Kim','Lee','Park','Choi','Jung','Kang','Yun','Lim','Han','Oh']
methods = ['portone','portone','portone','stripe']

start = datetime.date(2026,4,1)
end = datetime.date(2026,5,31)

inserted = 0
d = start
while d <= end:
    if d.weekday() < 5:
        for st, et in slot_times:
            try:
                cur.execute('INSERT OR IGNORE INTO Slot (SlotDate,StartTime,EndTime,MaxCount,BookedCount) VALUES (?,?,?,3,0)',
                            (str(d), st, et))
            except:
                pass
        conn.commit()
        for st, et in slot_times:
            cur.execute('SELECT Id FROM Slot WHERE SlotDate=? AND StartTime=?', (str(d), st))
            row = cur.fetchone()
            if not row:
                continue
            slot_id = row[0]
            count = random.randint(1, 3)
            cur.execute('UPDATE Slot SET BookedCount=? WHERE Id=?', (count, slot_id))
            for i in range(count):
                t = random.choice(treatments)
                name = random.choice(names)
                ds = str(d).replace('-','')
                code = 'VC' + ds + str(slot_id) + str(i)
                cur.execute('INSERT OR IGNORE INTO Reservation (SlotId,TreatmentId,PatientName,Nationality,Phone,Email,ConfirmCode,Status,CreatedAt) VALUES (?,?,?,?,?,?,?,?,?)',
                    (slot_id, t[0], name, 'KR', '010-0000-0001', 'test@test.com', code, 'DONE', str(d)+'T09:00:00'))
                cur.execute('SELECT Id FROM Reservation WHERE ConfirmCode=?', (code,))
                res_row = cur.fetchone()
                if not res_row:
                    continue
                res_id = res_row[0]
                method = random.choice(methods)
                cur.execute('INSERT OR IGNORE INTO Payment (ReservationId,Method,Amount,Status,PaymentKey,CreatedAt) VALUES (?,?,?,?,?,?)',
                    (res_id, method, t[2], 'PAID', 'pay'+code, str(d)+'T09:10:00'))
                inserted += 1
    d += datetime.timedelta(days=1)

conn.commit()
conn.close()
print('Done: ' + str(inserted) + ' rows')

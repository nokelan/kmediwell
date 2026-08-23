#!/usr/bin/env python3
"""567개 최저 매출 시나리오 데모 예약 데이터 생성"""
import sqlite3, random, uuid, json

DB = '/var/kmediwell/kmediwell.db'

# Treatment ID → Price (최저 매출 = 저가 중심 믹스)
TREAT_POOL = (
    [4] * 200 +  # 보톡스 150,000
    [5] * 130 +  # 필러 250,000
    [1] * 80  +  # 리쥬란 350,000
    [26] * 40 +  # 기본 페이셜 80,000
    [2] * 45  +  # 울쎄라 800,000
    [27] * 25 +  # 아로마 마사지 120,000
    [3] * 25  +  # 써마지 900,000
    [28] * 15 +  # 딥포어 100,000
    [29] * 4  +  # 발마사지 70,000
    [30] * 3     # 두피케어 65,000
)  # total 567

PRICES = {1:350000, 2:800000, 3:900000, 4:150000, 5:250000,
          26:80000, 27:120000, 28:100000, 29:70000, 30:65000}

# 월별 예약 수 (램프업)
MONTHLY = {6:20, 7:65, 8:80, 9:85, 10:95, 11:107, 12:115}

# 국적 (최저 = 한국인 비중 높게)
NAT_POOL = ['일본']*35 + ['중국']*20 + ['한국']*30 + ['미국']*8 + ['기타']*7

JP_NAMES = ['Tanaka Yuki','Suzuki Aoi','Watanabe Hana','Sato Miku','Yamamoto Rin',
            'Ito Nao','Kato Saki','Nakamura Mei','Hayashi Yui','Kimura Haru',
            'Ogawa Nana','Matsumoto Emi','Inoue Riko','Kobayashi Yuka','Yamada Ai']
CN_NAMES = ['Wang Fang','Li Na','Zhang Wei','Liu Yang','Chen Jing',
            'Yang Xue','Zhao Min','Wu Ling','Zhou Hua','Sun Hong',
            'Guo Mei','He Yan','Lin Xia','Xu Qian','Ma Jing']
KO_NAMES = ['김수진','이지은','박민주','최유리','정소연','한지혜','송미래',
            'Youn Chaewon','Lim Jisu','Kang Dayeon','Oh Soyeon','Shin Mina',
            'Jeong Yura','Lee Seojun','Park Jihoon']
EN_NAMES = ['Sarah Johnson','Emily Davis','Jessica Brown','Ashley Wilson',
            'Megan Taylor','Lauren Harris','Amanda Clark','Stephanie Lewis']

CHANNELS = ['DIRECT']*70 + ['CRUISE']*20 + ['PACKAGE']*10

def get_name(nat):
    if nat == '일본': return random.choice(JP_NAMES)
    if nat == '중국': return random.choice(CN_NAMES)
    if nat == '한국': return random.choice(KO_NAMES)
    return random.choice(EN_NAMES)

def get_phone(nat):
    r = lambda n: random.randint(10**(n-1), 10**n - 1)
    if nat == '일본': return f'+81-90-{r(4)}-{r(4)}'
    if nat == '중국': return f'+86-138-{r(4)}-{r(4)}'
    if nat == '한국': return f'010-{r(4)}-{r(4)}'
    return f'+1-{r(3)}-{r(3)}-{r(4)}'

def gen_code():
    return 'KMW-' + uuid.uuid4().hex[:8].upper()

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
c = conn.cursor()

# 월별 가용 슬롯 로드
slots_by_month = {}
for month in MONTHLY:
    d_from = '2026-06-21' if month == 6 else f'2026-{month:02d}-01'
    last = {1:31,2:28,3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31}[month]
    d_to = f'2026-{month:02d}-{last}'
    c.execute("SELECT Id, SlotDate FROM Slot WHERE SlotDate BETWEEN ? AND ? AND BookedCount < MaxCount AND IsBlocked=0 ORDER BY SlotDate, StartTime", (d_from, d_to))
    slots_by_month[month] = [(r['Id'], r['SlotDate']) for r in c.fetchall()]
    print(f"Month {month}: {len(slots_by_month[month])} available slots, need {MONTHLY[month]}")

treat_list = TREAT_POOL[:]
random.shuffle(treat_list)
nat_list = NAT_POOL * 10
random.shuffle(nat_list)
chan_list = CHANNELS * 10
random.shuffle(chan_list)

total_created = 0
monthly_stats = {}
idx = 0

for month, need in MONTHLY.items():
    avail = slots_by_month[month]
    if len(avail) < need:
        print(f"WARNING month {month}: only {len(avail)} slots, reducing to {len(avail)}")
        need = len(avail)

    chosen = random.sample(avail, need)
    month_revenue = 0

    for (slot_id, slot_date) in chosen:
        treat_id = treat_list[idx % len(treat_list)]
        price = PRICES[treat_id]
        nat = nat_list[idx % len(nat_list)]
        name = get_name(nat)
        phone = get_phone(nat)
        email = f'demo.{idx:04d}@example.com'
        code = gen_code()
        channel = chan_list[idx % len(chan_list)]
        day = random.randint(1, 20)
        hr = random.randint(8, 18)
        created = f'{slot_date[:7]}-{day:02d} {hr:02d}:{random.randint(0,59):02d}:00'
        method = random.choice(['stripe', 'stripe', 'portone'])  # 해외 카드 2/3

        c.execute("""INSERT OR IGNORE INTO Reservation
            (SlotId, TreatmentId, PatientName, Nationality, Phone, Email, ConfirmCode, Status, Channel, CreatedAt)
            VALUES (?,?,?,?,?,?,?,'DONE',?,?)""",
            (slot_id, treat_id, name, nat, phone, email, code, channel, created))

        res_id = c.lastrowid
        if res_id and c.rowcount > 0:
            pay_key = f'demo_{code}'
            c.execute("""INSERT OR IGNORE INTO Payment
                (ReservationId, Method, Amount, Status, PaymentKey, CreatedAt)
                VALUES (?,?,?,'COMPLETED',?,?)""",
                (res_id, method, price, pay_key, created))
            c.execute("UPDATE Slot SET BookedCount=BookedCount+1 WHERE Id=?", (slot_id,))
            month_revenue += price
            total_created += 1

        idx += 1

    monthly_stats[month] = {'count': need, 'revenue': month_revenue}

conn.commit()
conn.close()

print(f"\n=== 생성 완료: {total_created}건 ===")
print(f"{'월':>4} | {'건수':>5} | {'매출(만원)':>12} | {'인당(만원)':>10}")
print('-' * 45)
total_rev = 0
for month, stat in monthly_stats.items():
    rev = stat['revenue']
    cnt = stat['count']
    total_rev += rev
    avg = rev // cnt if cnt else 0
    print(f"{month:>4}월 | {cnt:>5} | {rev//10000:>10,}만 | {avg//10000:>8,}만")
print('-' * 45)
print(f"{'합계':>4} | {total_created:>5} | {total_rev//10000:>10,}만 | {(total_rev//total_created)//10000:>8,}만")

"""Compare the simulator's calendar dump (./build.sh test output) with pyluach.

    ./build.sh test > /tmp/dump.txt
    python3 tools/verify_calendar.py /tmp/dump.txt     # needs: pip install pyluach
"""
import sys
from pyluach import dates, parshios


def jdn_of(greg):
    y, m, d = greg.year, greg.month, greg.day
    a = (14 - m) // 12
    yy, mm = y + 4800 - a, m + 12 * a - 3
    return d + (153 * mm + 2) // 5 + 365 * yy + yy // 4 - yy // 100 + yy // 400 - 32045


def par(p):
    return '-' if p is None else ','.join(str(x) for x in p)


rows = [l[l.index('D|'):].strip().split('|') for l in open(sys.argv[1], encoding='utf-8') if 'D|' in l]
errors = 0
for r in rows:
    jdn, y, m, d = (int(x) for x in r[1:5])
    core_di, core_il, fast, omer = r[5], r[6], r[7], int(r[8])
    heb = dates.HebrewDate(y, m, d)
    problems = []
    if jdn_of(heb.to_greg()) != jdn:
        problems.append(f'date: pyluach {heb.to_greg()} jdn {jdn_of(heb.to_greg())}')
    if (heb.holiday(israel=False) is not None) != (core_di == '1'):
        problems.append(f'diaspora holiday: pyluach {heb.holiday(israel=False, hebrew=True)!r}')
    if (heb.holiday(israel=True) is not None) != (core_il == '1'):
        problems.append(f'israel holiday: pyluach {heb.holiday(israel=True, hebrew=True)!r}')
    if (heb.fast_day() is not None) != (fast == '1'):
        problems.append(f'fast: pyluach {heb.fast_day(hebrew=True)!r}')
    n = jdn - jdn_of(dates.HebrewDate(y, 1, 15).to_greg())
    if omer != (n if 1 <= n <= 49 else 0):
        problems.append(f'omer {omer} vs {n}')
    if heb.weekday() == 7:
        if r[9] != par(parshios.getparsha(heb, israel=False)):
            problems.append(f'parasha diaspora {r[9]} vs {par(parshios.getparsha(heb, israel=False))}')
        if r[10] != par(parshios.getparsha(heb, israel=True)):
            problems.append(f'parasha israel {r[10]} vs {par(parshios.getparsha(heb, israel=True))}')
    if problems:
        errors += 1
        if errors <= 20:
            print(f'{y}-{m}-{d} (jdn {jdn}):', '; '.join(problems))

years = sorted({int(r[2]) for r in rows})
print(f'{len(rows)} days checked, years {years[0]}-{years[-1]}, {errors} with differences')
sys.exit(1 if errors or not rows else 0)

BASE = 1600

for i in range(0, 12):
    freq = round((BASE * 2**(i/12)) / 7.8125)
    print(hex(freq))
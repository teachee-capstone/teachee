import numpy as np

DAC_MAX = 2**12-1

def sin(a, t):
    return a / 2 * (np.sin(t * 2 * np.pi) + 1)

def triangle(a, t):
    if t < 0.5:
        return 2 * a * t
    else:
        return 2 * a * (0.5 - (t - 0.5))


def square(a, t):
    if t < 0.5:
        return 0
    else:
        return a


FUNCS = [sin, triangle, square]

NUM_FUNCS=len(FUNCS)
NUM_AMPLITUDES=2**6
NUM_TIMES=2**8

signals = np.zeros((NUM_FUNCS, NUM_AMPLITUDES, NUM_TIMES), dtype=np.int32)

amplitudes = np.linspace(0, DAC_MAX, num=2**6)
times = np.linspace(0, 1, num=2**8)

for i, f in enumerate(FUNCS):
    for j, a in enumerate(amplitudes):
        for k, t in enumerate(times):
            signals[i, j, k] = np.int32(f(a, t))


np.set_printoptions(threshold=np.inf)

signal_str = f"""#define NUM_FUNCS {NUM_FUNCS}
#define NUM_AMPLITUDES {NUM_AMPLITUDES}
#define NUM_TIMES {NUM_TIMES}

const uint32_t signals[NUM_FUNCS][NUM_AMPLITUDES][NUM_TIMES] =
{np.array2string(signals, separator=',').replace('[', '{').replace(']', '}')};"""

print(signal_str)

"""Прогон приложения на эмуляторе: установка, запуск, несколько нажатий.

Ничего не «проверяет» сам — только собирает снимки экрана, дерево элементов
и журнал, чтобы их можно было посмотреть глазами. Не падает на середине:
каждый шаг записывает, что получилось, и идёт дальше.
"""
import pathlib
import re
import subprocess
import sys
import time

APK, OUT = sys.argv[1], pathlib.Path(sys.argv[2])
PKG = "nl.mikem.klubok"
OUT.mkdir(parents=True, exist_ok=True)
report = []


def adb(*args, timeout=120, binary=False):
    try:
        r = subprocess.run(["adb", *args], capture_output=True, timeout=timeout)
        return r.stdout if binary else (r.stdout + r.stderr).decode("utf-8", "replace").strip()
    except Exception as e:  # noqa: BLE001
        return b"" if binary else f"<<{e}>>"


def note(text):
    print(text, flush=True)
    report.append(text)


def shot(name):
    data = adb("exec-out", "screencap", "-p", binary=True)
    (OUT / f"{name}.png").write_bytes(data)
    note(f"[снимок] {name}.png — {len(data)} байт; процесс жив: {alive()}")


def alive():
    out = adb("shell", "pidof", PKG).strip()
    return bool(out) and all(part.isdigit() for part in out.split())


def dump(name=None):
    """Дерево элементов экрана: [(подпись, x, y)]."""
    for _ in range(3):
        adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
        xml = adb("exec-out", "cat", "/sdcard/ui.xml")
        if "<node" in xml:
            break
        time.sleep(1.5)
    if name:
        (OUT / f"{name}.xml").write_text(xml, encoding="utf-8")
    nodes = []
    for m in re.finditer(r"<node\b[^>]*>", xml):
        tag = m.group(0)
        label = " ".join(
            v for v in (
                (re.search(r'\btext="([^"]*)"', tag) or [None, ""])[1],
                (re.search(r'\bcontent-desc="([^"]*)"', tag) or [None, ""])[1],
            ) if v
        )
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', tag)
        if label and b:
            x1, y1, x2, y2 = map(int, b.groups())
            nodes.append((label.replace("&#10;", " "), (x1 + x2) // 2, (y1 + y2) // 2, (x2 - x1) * (y2 - y1)))
    return nodes


def tap(x, y):
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(1.2)


def tap_label(text, name=None, fallback=None):
    """Нажать на самый маленький элемент, в подписи которого есть text."""
    nodes = [n for n in dump(name) if text.lower() in n[0].lower()]
    if nodes:
        label, x, y, _ = min(nodes, key=lambda n: n[3])
        note(f"[нажатие] «{text}» → ({x},{y}), подпись: {label[:70]!r}")
        tap(x, y)
        return True
    if fallback:
        note(f"[нажатие] «{text}» не найден в дереве, жму по запасным координатам {fallback}")
        tap(*fallback)
        return False
    note(f"[нажатие] «{text}» не найден")
    return False


def dismiss_anr():
    """На медленном эмуляторе системные приложения иногда «не отвечают» — жмём «Wait»."""
    for _ in range(3):
        nodes = dump()
        if not any("responding" in n[0] for n in nodes):
            return
        wait = [n for n in nodes if n[0].strip() == "Wait"]
        note("[эмулятор] системное окно «isn't responding» — жму Wait")
        if wait:
            tap(wait[0][1], wait[0][2])
        time.sleep(3)


size = adb("shell", "wm", "size")
m = re.search(r"(\d+)x(\d+)", size)
W, H = (int(m.group(1)), int(m.group(2))) if m else (1080, 2400)
note(f"Экран: {W}x{H}; Android {adb('shell', 'getprop', 'ro.build.version.release')}, ABI {adb('shell', 'getprop', 'ro.product.cpu.abi')}")

note("[установка] " + adb("install", "-r", APK, timeout=300).replace("\n", " | "))
dismiss_anr()
adb("logcat", "-c")
note("[запуск] " + adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1").splitlines()[-1])
time.sleep(12)
dismiss_anr()
time.sleep(2)
shot("01-start")
note("[экран] " + " · ".join(n[0] for n in dump("01-start"))[:600])

# Новый проект
tap_label("Новый проект", fallback=(W // 2, int(H * 0.60)))
time.sleep(1.5)
shot("02-new-project")
if tap_label("Что вяжем", "02-new-project", fallback=(W // 2, int(H * 0.47))):
    pass
adb("shell", "input", "text", "Sviter")
time.sleep(1)
shot("03-typed")
for _ in range(3):
    adb("shell", "input", "swipe", str(W // 2), str(int(H * 0.55)), str(W // 2), str(int(H * 0.15)), "250")
    time.sleep(0.8)
shot("04-form-bottom")
tap_label("Создать проект", "04-form-bottom", fallback=(W // 2, int(H * 0.5)))
time.sleep(2)
shot("05-counter")
note("[экран] " + " · ".join(n[0] for n in dump("05-counter"))[:600])

# Счётчик: три нажатия на клубок, громкость вверх ×2, вниз ×1 → должно стать 4
found = [n for n in dump() if "чтобы прибавить" in n[0].lower()]
bx, by = (found[0][1], found[0][2]) if found else (W // 2, int(H * 0.47))
note(f"[клубок] {'найден' if found else 'не найден, беру центр'}: ({bx},{by})")
for _ in range(3):
    tap(bx, by)
shot("06-after-3-taps")
adb("shell", "input", "keyevent", "KEYCODE_VOLUME_UP"); time.sleep(0.8)
adb("shell", "input", "keyevent", "KEYCODE_VOLUME_UP"); time.sleep(0.8)
adb("shell", "input", "keyevent", "KEYCODE_VOLUME_DOWN"); time.sleep(1.2)
shot("07-after-volume-keys")
note("[экран] " + " · ".join(n[0] for n in dump("07-after-volume-keys"))[:600])

# Остальные вкладки
tap_label("Проекты", fallback=(W // 2, int(H * 0.955)))
time.sleep(1.5)
shot("08-projects")
tap_label("Пряжа", fallback=(int(W * 0.83), int(H * 0.955)))
time.sleep(1.5)
shot("09-yarn")
tap_label("Добавить пряжу", fallback=(W // 2, int(H * 0.60)))
time.sleep(1.5)
shot("10-yarn-form")

log = adb("logcat", "-d", "-v", "time", timeout=180)
(OUT / "logcat.txt").write_text(log, encoding="utf-8")
bad = [l for l in log.splitlines() if re.search(r"FATAL EXCEPTION|AndroidRuntime|E/flutter|I/flutter|Unhandled Exception|" + re.escape(PKG), l)]
(OUT / "logcat-app.txt").write_text("\n".join(bad), encoding="utf-8")
note(f"[журнал] строк всего {len(log.splitlines())}, про приложение {len(bad)}; FATAL: {sum('FATAL' in l for l in bad)}, E/flutter: {sum('E/flutter' in l for l in bad)}")
note(f"[итог] процесс жив в конце: {alive()}")
(OUT / "report.txt").write_text("\n".join(report), encoding="utf-8")

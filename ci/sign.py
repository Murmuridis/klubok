"""Подписывает APK постоянным ключом из ci/debug.keystore.

`flutter create` генерирует android/app/build.gradle(.kts), где release-сборка
подписывается отладочным ключом. Сам Gradle берёт этот ключ из домашней папки
сборочной машины и каждый раз создаёт новый, поэтому здесь отладочной подписи
явно указывается ключ из репозитория. Одинаковая подпись = обновление ставится
поверх старой версии и записи в приложении сохраняются.
"""
import pathlib

app = pathlib.Path(__file__).resolve().parent.parent / "android" / "app"
kts = app / "build.gradle.kts"
groovy = app / "build.gradle"
MARK = "ci/debug.keystore"

if kts.exists():
    target, block = kts, '''
android {
    signingConfigs {
        getByName("debug") {
            storeFile = file("../../ci/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
}
'''
elif groovy.exists():
    target, block = groovy, '''
android {
    signingConfigs {
        debug {
            storeFile file("../../ci/debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }
}
'''
else:
    raise SystemExit("Не найден android/app/build.gradle(.kts) — сначала flutter create")

text = target.read_text(encoding="utf-8")
if MARK not in text:
    target.write_text(text + block, encoding="utf-8")
print(f"Подпись настроена в {target.name}")

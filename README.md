# Mini ERP — mobile

Ichimliklar do'koni uchun mini-ERP mobil ilovasi (Flutter, faqat Android). Ombor, savdo, xarid, inventarizatsiya, kassa, kontragentlar va hisobotlarni backend API orqali boshqaradi. Ilova tili — o'zbekcha (lotin).

Backend repo: <https://github.com/muzakov02/mini-erp-backend>

Loyiha hujjatlari (arxitektura qarorlari va foydalanuvchi qo'llanmasi) backend repo'ning `docs/` papkasida.

## Talablar

- Flutter 3.44.8 (loyiha shu versiya bilan ishlab chiqilgan), Dart `^3.12.2` (`pubspec.yaml`)
- Android qurilma yoki emulyator
- Ishlayotgan backend (backend README ga qarang)

## Ishga tushirish

Barcha buyruqlar PowerShell uchun.

```powershell
flutter pub get
```

Server manzili `--dart-define=API_BASE_URL` bilan beriladi. Berilmasa, ilova ochilganda manzil kerakligi haqida xabar ko'rsatadi.

Haqiqiy telefonda (telefon va kompyuter **bitta Wi-Fi tarmog'ida** bo'lishi kerak; `<kompyuter-IP>` ni `ipconfig` dan oling):

```powershell
flutter run --dart-define=API_BASE_URL=http://<kompyuter-IP>:3000/api
```

Android emulyatorida kompyuterga `10.0.2.2` orqali ulaniladi:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Backend lokal HTTP da ishlagani uchun manifestda `INTERNET` ruxsati va `usesCleartextTraffic` yoqilgan. Windows firewall 3000-portni to'sayotgan bo'lsa, backend README dagi eslatmaga qarang.

## APK yig'ish

```powershell
flutter build apk --dart-define=API_BASE_URL=http://<kompyuter-IP>:3000/api
```

Tayyor fayl: `build\app\outputs\flutter-apk\app-release.apk`. Manzil APK ichiga yig'ish vaqtida yoziladi: IP o'zgarsa, qayta yig'ing.

## Ekranlar

Pastki navigatsiyada 5 tab (ilova **Hisobotlar** dan ochiladi):

| Tab | Mazmuni |
|---|---|
| Hisobotlar | Davr tanlagich (Bugun / Shu oy / Barchasi / Oraliq), kassa qoldig'i, foyda va zarar, foydaga kirmagan harakatlar; savdo va qoldiq hisobotlari |
| Hujjatlar | Savdo, Xarid, Inventarizatsiya: ro'yxat, holat filtri, qoralama → bajarish |
| Kassa | Kassa qoldig'i, operatsiyalar, turkum filtri, kirim va chiqim kiritish |
| Ombor | Mahsulotlar (qoldiq dona va blokda) va omborlar (daraxt, sub-omborlar) |
| Kontragentlar | Mijoz, yetkazib beruvchi, boshqa; balans, hisob-kitob tarixi |

## Arxitektura

Feature-first tuzilma:

```
lib/
  main.dart, app.dart
  core/       config, di, errors, format, models, network, router, state, widgets
  features/   products, warehouses, stock, counterparties, documents, cash, reports
                data/          modellar, repository
                presentation/  cubit, sahifalar
```

- **Holat boshqaruvi:** Cubit (`flutter_bloc`, `equatable`)
- **Tarmoq:** `dio`; interceptor backend xatosini `AppFailure(code, message, details)` ga aylantiradi, har kod uchun o'zbekcha xabar
- **DI:** `get_it`
- **Navigatsiya:** `go_router` (`StatefulShellRoute`)
- **Pul:** `decimal`; backenddan string keladi, `double` ishlatilmaydi, backendga string yuboriladi
- **Format:** `intl`; pul "366 000 so'm", sana ekranda `dd.MM.yyyy`

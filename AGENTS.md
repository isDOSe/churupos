# Contexto del proyecto — churupos

App Flutter. El resultado se prueba siempre en un dispositivo, no solo en tests.

## Repositorio público

El repo es público. **No** meter specs, agentes ni notas internas: eso vive en la
documentación interna (vault de Obsidian), fuera del repo.

## Checklist obligatorio al modificar la app

1. Abrir el resultado en el emulador `Celularzote_Pixel_8`.
2. Subir la versión en `pubspec.yaml`.
3. Actualizar `CHANGELOG.md` y `README.md`.
4. `flutter analyze` y `flutter test`.
5. Generar el APK de prueba en `dist/churupos-<versión>.apk`.

## Crédito visible

**“Hecho por DOSe”**. Nunca “Hecho por isdose.com”: `isdose.com` es el sitio,
no el autor.

## Antes de publicar en Play Store

Hace falta, y no es opcional:

- keystore de release propio (el de debug no sirve),
- política de privacidad,
- formulario Data Safety,
- ficha completa de la tienda.

La operación y el release están documentados en la documentación interna.

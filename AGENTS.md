# Contexto del proyecto — churupos

App Flutter (Android) con su landing publicada en
`https://isdose.com/lab/churupos/`.

## Estructura

```
app/       proyecto Flutter completo (lib/, test/, android/, assets/, pubspec.yaml)
web/       landing estática, sin build
docs/      capturas y documentación de tienda
dist/      APK de prueba (en .gitignore)
scripts/   generadores de iconos y gráficos (python)
```

Los comandos de Flutter se ejecutan **dentro de `app/`**.

## Repositorio público

El repo es público. **No** meter specs, agentes ni notas internas: eso vive en la
documentación interna (vault de Obsidian), fuera del repo.

## Checklist obligatorio al modificar la app

1. Abrir el resultado en el emulador `Celularzote_Pixel_8`.
2. Subir la versión en `app/pubspec.yaml`.
3. Actualizar `CHANGELOG.md` y `README.md`.
4. `cd app`, luego `flutter analyze` y `flutter test`.
5. Generar el APK de prueba en `dist/churupos-<versión>.apk`.

## Landing

- Vive en `web/`: HTML/CSS estático, sin build.
- Se prueba con `python -m http.server 4173 --directory web`.
- No se despliega por separado: el sitio de isdose copia `web/` con
  `npm run labs:sync` (ver `docs/labs.md` en el repo de isdose).
- Rutas relativas siempre: se sirve desde un subdirectorio.

## Crédito visible

**“Hecho por DOSe”**. Nunca “Hecho por isdose.com”: `isdose.com` es el sitio, no
el autor.

## Antes de publicar en Play Store

Hace falta, y no es opcional:

- keystore de release propio (el de debug no sirve),
- política de privacidad,
- formulario Data Safety,
- ficha completa de la tienda.

La operación y el release están documentados en la documentación interna.

# Retro Game Vault

Catálogo personal de videojuegos, pensado primero para móvil y con estética retro/neón.

## Objetivos
- Catálogo con búsqueda, filtros por plataforma y ordenación.
- Fichas con edición, región (prioridad PAL España), año, estado, completitud y notas.
- Fotografías privadas: portada, contraportada, disco/cartucho y detalles.
- Valoración orientativa separada de precios observados, con histórico y procedencia.
- Importación/exportación para copias de seguridad.
- Acceso exclusivo del propietario mediante autenticación y políticas de base de datos.

## Privacidad y arquitectura
GitHub Pages publica la web en Internet. El repositorio aloja el código de la interfaz; no debe contener fotos, fichas personales, copias JSON ni contraseñas.

La integración prevista utiliza Supabase:
- Autenticación para identificar al propietario.
- PostgreSQL con Row Level Security (RLS).
- Bucket privado y políticas que limitan cada carpeta al usuario autenticado.
- La clave publicable/anon puede estar en el navegador; nunca subir la clave service_role, contraseñas ni secretos.

El archivo [supabase-schema.sql](./supabase-schema.sql) prepara las tablas, políticas RLS y almacenamiento privado. La web actual no se conecta todavía a Supabase: primero hay que crear y configurar el proyecto del propietario y probar el inicio de sesión.

## Configuración de Supabase
1. Crear un proyecto Supabase con el plan Free.
2. Abrir SQL Editor, pegar supabase-schema.sql y ejecutar.
3. Crear el usuario propietario desde Authentication > Users.
4. Desactivar después el registro público en Authentication > Settings.
5. Copiar Project URL y publishable key (o anon key heredada) desde Project Settings > API.
6. Configurar esos dos valores en la aplicación cuando esté lista. Nunca usar service_role en el navegador.

## Límites gratuitos
A fecha de 22-11-2026, Supabase muestra en Free 500 MB de base de datos, 1 GB de almacenamiento de archivos y 5 GB de transferencia. Los proyectos con poca actividad pueden pausarse tras 7 días. El plan Free no incluye copias de seguridad automáticas del plan Pro. Se añadirá exportación manual de datos y fotos; no depender de un único proveedor.

## Modelo de datos
- games: ficha principal, edición/estado, valoración y rutas de fotos.
- price_observations: observaciones fechadas, distinguiendo precio anunciado de venta cerrada y guardando fuente/condición.
- storage.game-photos: bucket privado separado por UUID del propietario.

## Criterio de valoración
No presentar un precio como tasación exacta ni inventar ventas. La valoración debe justificarse con observaciones comparables, región, edición, estado y contenido. Los anuncios activos y las ventas cerradas no son equivalentes.

## Estado del proyecto
- [x] Revisada la web existente: guardaba datos solo en IndexedDB del navegador.
- [x] Decidido separar frontend público de datos privados.
- [x] Creado esquema inicial con RLS y bucket privado.
- [ ] Crear/configurar el proyecto Supabase del propietario.
- [ ] Conectar autenticación y catálogo.
- [ ] Implementar gestión de fotos y compresión.
- [ ] Implementar importación/exportación completa y restauración.
- [ ] Probar desde móvil y escritorio.

La web actual se conserva mientras se prepara la nueva arquitectura. No se borran ni migran automáticamente los registros antiguos.

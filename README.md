# Sistema de Gestión Inmobiliaria — MySQL

Prototipo de base de datos para una inmobiliaria: administra el portafolio de propiedades (casas, apartamentos, locales comerciales), los clientes, los contratos (venta/arriendo) y el historial de pagos. Incluye funciones personalizadas, triggers de auditoría, seguridad por roles, índices de optimización y un evento programado mensual.

## Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `inmobiliaria_db.sql` | Script principal: crea la base de datos, tablas, índices, funciones, triggers, roles/usuarios, el evento programado y un set inicial de datos de ejemplo. |
| `datos_prueba_inmobiliaria.sql` | Datos adicionales que cubren casos de prueba específicos (comisiones distintas, deuda al día, deuda atrasada, pago parcial, cambio de estado manual) y consultas guía para verificar los roles. |

## Requisitos

- MySQL **8.0 o superior** (se usan `CREATE ROLE` y `SET DEFAULT ROLE`, disponibles desde 8.0).
- Usuario con privilegios suficientes para crear bases de datos, roles, usuarios, funciones, triggers y eventos (normalmente `root` o un administrador).
- El **Event Scheduler** debe poder activarse (`SET GLOBAL event_scheduler = ON`), incluido en el script.

## Cómo ejecutarlo

```bash
mysql -u root -p < inmobiliaria_DB.sql
```

O bien abre ambos archivos en MySQL Workbench y ejecútalos en ese orden (el segundo depende de los datos creados por el primero).

## 1. Modelo de datos (normalizado a 3FN)

| Tabla | Rol |
|---|---|
| `tipos_propiedad` | Catálogo de tipos de inmueble (casa, apartamento, local comercial) |
| `agentes` | Agentes inmobiliarios, cada uno con su propio porcentaje de comisión |
| `clientes` | Compradores y/o arrendatarios |
| `propiedades` | Inventario de inmuebles, con su estado (`disponible`, `arrendada`, `vendida`) |
| `contratos` | Contrato de venta o arriendo entre un cliente, una propiedad y un agente |
| `pagos` | Abonos asociados a un contrato de arriendo (relación 1:N) |
| `historial_estados_propiedad` | Auditoría de cada cambio de estado de una propiedad |
| `auditoria_contratos` | Auditoría de eventos sobre contratos (p. ej. su creación) |
| `reportes_pagos_pendientes` | Salida generada por el evento programado mensual |

**Decisiones de diseño principales:**

- `tipos_propiedad` está separado de `propiedades` para no repetir el nombre del tipo como texto libre en cada fila (evita inconsistencias como `"Apartamento"` vs `"apartamento"`).
- `agentes` y `clientes` son tablas independientes porque tienen atributos y reglas de negocio distintas (comisión vs. tipo de interés); combinarlos en una tabla "personas" genérica generaría columnas nulas innecesarias.
- `pagos` es una tabla aparte de `contratos` porque un contrato de arriendo genera múltiples pagos a lo largo del tiempo (relación 1:N); meterlos como columnas de `contratos` violaría 1FN.
- `valor_mensual` vive en `contratos` y no en `propiedades`, porque el canon puede negociarse por contrato específico.
- Las tablas de auditoría están separadas de las tablas operativas para no mezclar el dato "vivo" con su historial, y para poder asignarles privilegios distintos por rol.

## 2. Funciones personalizadas (UDFs)

| Función | Qué hace |
|---|---|
| `fn_calcular_comision(id_contrato)` | Calcula la comisión del agente sobre un contrato de **venta**: `valor_total * porcentaje_comision`. Devuelve 0 si el contrato es de arriendo. |
| `fn_calcular_deuda_pendiente(id_contrato)` | Calcula la deuda de un contrato de **arriendo**: meses transcurridos desde `fecha_inicio` × canon mensual, menos la suma de lo ya pagado en `pagos`. Nunca devuelve un valor negativo. |
| `fn_total_disponibles_por_tipo(id_tipo)` | Cuenta cuántas propiedades de un tipo dado están en estado `disponible`. |

## 3. Triggers de auditoría

| Trigger | Evento | Qué hace |
|---|---|---|
| `trg_propiedad_cambio_estado` | `AFTER UPDATE` en `propiedades` | Si el `estado` cambió, inserta un registro en `historial_estados_propiedad` con el estado anterior y el nuevo. |
| `trg_nuevo_contrato_auditoria` | `AFTER INSERT` en `contratos` | Registra la creación del contrato en `auditoria_contratos` y actualiza automáticamente el estado de la propiedad (`vendida` o `arrendada`), lo cual dispara en cascada el trigger anterior. |

## 4. Seguridad: roles y usuarios

| Rol | Puede hacer |
|---|---|
| `rol_administrador` | Todo (`ALL PRIVILEGES`) sobre la base de datos. |
| `rol_agente` | Gestionar propiedades y clientes, crear contratos, consultar agentes e historial de estados. No puede tocar pagos ni auditoría de contratos. |
| `rol_contador` | Registrar y consultar pagos, consultar contratos y reportes de pagos pendientes. No puede modificar el inventario de propiedades. |

Usuarios de ejemplo: `admin_maria`, `agente_juan`, `contador_luis` (contraseña de ejemplo `CambiarPassword123!` — cámbiala antes de usar esto fuera de un entorno de pruebas).

## 5. Índices de optimización

Se indexaron las columnas que efectivamente se usan en los `WHERE`/`JOIN` de las funciones, triggers y el evento programado (estado de propiedad, tipo de propiedad, estado+tipo de contrato, la FK de contrato→propiedad, y contrato+mes en pagos). No se indexó todo para no penalizar innecesariamente los `INSERT`/`UPDATE`.

## 6. Evento programado

`evt_reporte_mensual_pagos_pendientes` corre una vez al mes y, para cada contrato de arriendo activo con deuda pendiente, inserta una fila en `reportes_pagos_pendientes` usando `fn_calcular_deuda_pendiente`.

## Casos cubiertos en los datos de prueba

- Comisiones con distintos porcentajes de agente.
- Un contrato de arriendo al día (deuda = 0).
- Un contrato de arriendo atrasado con pago parcial (deuda > 0).
- Un cambio de estado de propiedad hecho manualmente (sin pasar por un contrato), para confirmar que el trigger de historial reacciona por sí solo.
- Consultas guía (comentadas) para verificar qué operaciones permite o bloquea cada rol.

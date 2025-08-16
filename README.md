# Clínica San Martín DB

Base de datos clínica diseñada en **MySQL 8.0+** para gestionar **pacientes, citas, historias clínicas** y **trazabilidad de medicamentos**, con **particionado por rango de fechas**, **procedimientos almacenados para facturación** y **políticas de acceso basadas en roles**. Optimizada con índices compuestos y estrategias de auditoría para preservar integridad y cumplimiento.

---

## Tabla de contenidos
- [Objetivo y Alcance](#objetivo-y-alcance)
- [Requisitos](#requisitos)
- [Modelo de Datos (visión general)](#modelo-de-datos-visión-general)
- [Principios de Diseño](#principios-de-diseño)
- [Diagrama](#diagrama)
- [Tablas Clave](#tablas-clave)
- [Reglas de Negocio](#reglas-de-negocio)
- [Índices, Particionado y Rendimiento](#índices-particionado-y-rendimiento)
- [Facturación](#facturación)
- [Seguridad y Cumplimiento](#seguridad-y-cumplimiento)
- [Operación y Mantenimiento](#operación-y-mantenimiento)
- [KPIs](#kpis)
- [Roadmap](#roadmap)
- [Cómo empezar](#cómo-empezar)
- [Licencia](#licencia)

---

## Objetivo y Alcance
**Objetivo:** soportar la operación clínica end-to-end con foco en calidad de datos, trazabilidad de actos asistenciales y eficiencia operativa.

**Incluye:** registro maestro de pacientes, gestión de citas, episodios/encuentros clínicos, diagnósticos y procedimientos, prescripciones, inventario y dispensación de medicamentos, facturación (procedimientos almacenados), auditoría y reportes.

**Fuera de alcance:** HIS/EMR completo de notas clínicas ricas (puede integrarse), motores de reglas clínicas y sistemas fiscales locales (conectables).

---

## Requisitos
- **Motor:** MySQL **8.0+**, motor **InnoDB**.
- **Codificación y TZ:** `utf8mb4` y `UTC` en servidor; TZ locales en la app.
- **Configuración sugerida:** `sql_mode=STRICT_ALL_TABLES`, binlog row-based para PITR.
- **Herramientas útiles:** `performance_schema`, `sys` schema para observabilidad.
- **Backups:** binlogs + snapshots diarios.

---

## Modelo de Datos (visión general)
Módulos y relaciones principales:
- **Pacientes:** `patient` (perfil) + `patient_identifier` (DNI/seguros) + `address`.
- **Citas:** `appointment` + `appointment_status_history`.
- **Encuentros clínicos:** `encounter` (episodio) + `diagnosis` (CIE-10) + `procedure` + `clinical_note` (texto estructurado).
- **Medicamentos:** `medication` (catálogo) + `medication_lot` + `medication_stock` + `dispensation` / `dispensation_item`.
- **Prescripciones:** `prescription` + `prescription_item`.
- **Facturación:** `invoice` + `invoice_line` + `payer` (seguro/particular) + `claim` (opcional).
- **Personal y roles:** `staff_user`, `role`, `role_assignment`.
- **Auditoría:** `audit_log`.

---

## Principios de Diseño
- **3FN** con claves naturales donde aporte (p. ej., `(patient_id, identifier_type)`).
- Timestamps `created_at`/`updated_at` y `performed_at` para actos clínicos.
- **Particionado temporal** en tablas voluminosas (`encounter`, `appointment`, `dispensation`, `invoice`).
- Enumeraciones implementadas como **CHECK** o dominios controlados por catálogo (`status`, `priority`, `sex`, etc.).
- **Soft-delete selectivo** (`deleted_at`) solo donde se requiera preservar histórico visible.
- Integridad referencial estricta; snapshots (por ejemplo, nombre del profesional y tarifa aplicada) en líneas de factura.

---

## Diagrama
> Coloca la imagen en `img/Skills/bd/clinica_san_martin_diagrama.png` dentro del repo.

![Diagrama ER](img/Skills/bd/clinica_san_martin_diagrama.png)

---

## Tablas Clave
- **Pacientes:** `patient`, `patient_identifier`, `address`.
- **Citas:** `appointment`, `appointment_status_history`.
- **Encuentros:** `encounter`, `diagnosis` (CIE-10), `procedure`, `clinical_note`.
- **Prescripciones y Medicación:** `prescription`, `prescription_item`, `medication`, `medication_lot`, `medication_stock`, `dispensation`, `dispensation_item`.
- **Facturación:** `invoice`, `invoice_line`, `payer`, `coverage` (si aplica), `claim` (opcional).
- **Personal y Accesos:** `staff_user`, `role`, `role_assignment`.
- **Auditoría:** `audit_log`.

---

## Reglas de Negocio
1. Un **patient** puede tener múltiples identificadores oficiales y de seguro, pero cada `(identifier_type, identifier_value)` es **único**.
2. Una **appointment** referencia paciente, profesional y especialidad, con flujo de estado: `scheduled → confirmed → in_progress → completed` (ramas `no_show`/`cancelled`).
3. Un **encounter** se crea al iniciar atención; diagnósticos (CIE-10) y procedimientos se asocian al encuentro.
4. **Prescriptions** requieren profesional y diagnóstico asociado; su **dispensation** valida stock y registra **lote** y **fecha de caducidad**.
5. La **facturación** se basa en los actos realizados (procedures) y materiales/medicación dispensada; descuentos/copagos se aplican por **coverage/payer**.
6. Toda mutación clínica, de inventario o facturación genera **audit_log** con actor, origen y before/after.

---

## Índices, Particionado y Rendimiento
- **B-Tree:** `patient(last_name, first_name)`, `patient_identifier(identifier_value)`, `appointment(doctor_id, scheduled_at)`, `dispensation_item(medication_id, performed_at)`.
- **Compuestos:** `(patient_id, scheduled_at)` en `appointment`; `(encounter_id, code)` en `diagnosis`/`procedure`.
- **Texto parcial (prefix):** índices sobre `last_name`/`first_name` para búsqueda rápida.
- **Particionado por rango de fechas** (mensual/trimestral) en `encounter`, `appointment`, `invoice`, `dispensation` (clave `performed_at`/`scheduled_at`).
- **Caching lógico** mediante vistas para listados frecuentes (agenda del día, stock vigente por medicamento).
- **Mantenimiento:** ANALYZE y ajuste de `innodb_buffer_pool_size` según huella.

---

## Facturación
- **Procedimientos almacenados** para: cálculo de **co-pago**, generación de **invoice** desde un `encounter`, validación de **cobertura** y registro de **pagos**.
- **Reglas tarifarias** por especialidad/profesional, horario (nocturno/feriado) y convenio con aseguradoras.
- **Conciliación**: reporte de diferencias entre actos realizados y facturados; manejo de **reclamaciones (claim)** opcional.

---

## Seguridad y Cumplimiento
- **Roles MySQL 8.0:** `admin`, `clinician`, `reception`, `pharmacy`, `billing`, `report_read`.
- **Separación de funciones:** vistas específicas por rol (p. ej., vista de agenda sin PII completa para recepción).
- **PII/PHI:** cifrar tokens y datos sensibles con **`AES_ENCRYPT`/KMS**; minimizar exposición en datasets analíticos.
- **Auditoría:** `audit_log` obligatorio en cambios de cita, diagnóstico, prescripción, dispensación y facturación.
- **Retención:** políticas por normativa local (historia clínica y documentos contables).

---

## Operación y Mantenimiento
- **Migraciones** versionadas (ej.: `2025_08_16_001_create_encounter`).
- **Backups:** snapshots diarios + binlogs para **PITR**; pruebas de restore periódicas.
- **Observabilidad:** `performance_schema`, `sys.user_summary`, latencias P95 por consulta crítica (agenda, búsqueda de paciente, facturación).
- **Datos maestros:** catálogos de CIE-10/Especialidades versionados.

---

## KPIs
- **No-show rate** de citas por especialidad/doctor.
- **Tiempo medio de atención** por encuentro.
- **Rotación de stock** y **quiebres** de medicamentos.
- **Ingresos** por especialidad y **recaudación** por pagador.
- **Tiempo a facturación** (encounter → invoice).

---

## Roadmap
- **Rastreo de alergias e inmunizaciones** (tablas dedicadas).
- **Firma digital** de notas clínicas y recetas.
- **Interoperabilidad** (FHIR export).
- **Control de lotes avanzados** con alertas de caducidad.
- **Particionado** adicional en `audit_log` para alto volumen.

---

## Cómo empezar
1. **Requisitos:** MySQL 8.0+ (InnoDB), `utf8mb4`, TZ `UTC`.
2. **Estructura del repo:** incluye el diagrama en `img/Skills/bd/clinica_san_martin_diagrama.png` y el script en `clinica_san_martin.sql`.
3. **Carga del esquema:** ejecuta el script SQL con tu herramienta preferida (`mysql`/Workbench).
4. **Usuarios y roles:** crea usuarios y asigna roles (`role_assignment`) según el perfil operativo.

> **Nota:** Este README describe el modelo y reglas de *Clínica San Martín DB* **sin incluir el código SQL** del esquema.

---

## Licencia
Define aquí la licencia del proyecto (por ejemplo, MIT, Apache-2.0, etc.).

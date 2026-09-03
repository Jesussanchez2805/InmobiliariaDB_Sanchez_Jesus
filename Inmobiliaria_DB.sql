-- =====================================================================
-- SISTEMA DE GESTIÓN INMOBILIARIA - MySQL
-- Prototipo: propiedades, clientes, contratos, pagos, auditoría,
-- seguridad por roles y evento programado.
-- =====================================================================
 
-- ---------------------------------------------------------------------
-- 1. BASE DE DATOS
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- DECISIONES DE DISEÑO
-- tipos_propiedad separado de propiedades: si guardara "apartamento" como texto libre en cada fila de propiedades,
-- tendría redundancia y riesgo de inconsistencia ("Apartamento" vs "apartamento").
-- agentes y clientes separados: tienen atributos y reglas de negocio distintas (un agente tiene porcentaje_comision,
-- un cliente tiene tipo_cliente). Fusionarlos en una tabla "personas" genérica generaría columnas nulas y complicaría los triggers/roles de seguridad.
-- pagos como tabla independiente de contratos: un contrato de arriendo genera múltiples pagos mensuales (relación 1:N).
-- Si guardara los pagos como columnas dentro de contratos, violaría 1FN (grupos repetitivos).
-- valor_mensual vive en contratos, no en propiedades: el precio de arriendo puede negociarse por contrato específico, así que depende de la clave del contrato, no únicamente de la propiedad 
-- Relaciones: tipos_propiedad (1)—(N) propiedades, agentes (1)—(N) propiedades (agente asignado),
-- propiedades (1)—(N) contratos, clientes (1)—(N) contratos, agentes (1)—(N) contratos, contratos (1)—(N) pagos.
-- ---------------------------------------------------------------------


CREATE DATABASE IF NOT EXISTS inmobiliaria_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE inmobiliaria_db;

CREATE TABLE tipos_propiedad (
    id_tipo INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE agentes (
    id_agente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    documento VARCHAR(20) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    porcentaje_comision DECIMAL(5,2) NOT NULL DEFAULT 3.00,
    activo TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    documento VARCHAR(20) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    tipo_cliente ENUM('comprador','arrendatario','ambos') NOT NULL DEFAULT 'ambos'
);

CREATE TABLE propiedades (
    id_propiedad INT AUTO_INCREMENT PRIMARY KEY,
    id_tipo INT NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    area_m2 DECIMAL(8,2),
    precio_venta DECIMAL(14,2),
    precio_arriendo_mensual DECIMAL(12,2),
    estado ENUM('disponible','arrendada','vendida') NOT NULL DEFAULT 'disponible',
    id_agente_asignado INT,
    fecha_registro DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_propiedad_tipo FOREIGN KEY (id_tipo) REFERENCES tipos_propiedad(id_tipo),
    CONSTRAINT fk_propiedad_agente FOREIGN KEY (id_agente_asignado) REFERENCES agentes(id_agente)
);

CREATE TABLE contratos (
    id_contrato INT AUTO_INCREMENT PRIMARY KEY,
    id_propiedad INT NOT NULL,
    id_cliente INT NOT NULL,
    id_agente INT NOT NULL,
    tipo_contrato ENUM('venta','arriendo') NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    valor_total DECIMAL(14,2) NOT NULL,
    valor_mensual DECIMAL(12,2),
    estado ENUM('activo','finalizado','cancelado') NOT NULL DEFAULT 'activo',
    CONSTRAINT fk_contrato_propiedad FOREIGN KEY (id_propiedad) REFERENCES propiedades(id_propiedad),
    CONSTRAINT fk_contrato_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_contrato_agente FOREIGN KEY (id_agente) REFERENCES agentes(id_agente)
);

CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato INT NOT NULL,
    fecha_pago DATE NOT NULL,
    mes_correspondiente DATE NOT NULL COMMENT 'primer día del mes que cubre el pago',
    valor_pagado DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM('efectivo','transferencia','tarjeta') NOT NULL DEFAULT 'transferencia',
    CONSTRAINT fk_pago_contrato FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato)
);

CREATE TABLE historial_estados_propiedad (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_propiedad INT NOT NULL,
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(100),
    CONSTRAINT fk_hist_propiedad FOREIGN KEY (id_propiedad) REFERENCES propiedades(id_propiedad)
);

CREATE TABLE auditoria_contratos (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_contrato INT NOT NULL,
    accion VARCHAR(50) NOT NULL,
    detalle VARCHAR(255),
    fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(100),
    CONSTRAINT fk_audit_contrato FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato)
);

CREATE TABLE reportes_pagos_pendientes (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_contrato INT NOT NULL,
    id_propiedad INT NOT NULL,
    id_cliente INT NOT NULL,
    deuda_pendiente DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_reporte_contrato FOREIGN KEY (id_contrato) REFERENCES contratos(id_contrato)
);
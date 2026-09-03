-- ---------------------------------------------------------------------
-- Seguridad y usuarios: creación de roles y privilegios diferenciados (admin, agente, contador).
-- ---------------------------------------------------------------------
 
CREATE ROLE 'rol_administrador', 'rol_agente', 'rol_contador';
 
GRANT ALL PRIVILEGES ON inmobiliaria_db.* TO 'rol_administrador';
 
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.propiedades TO 'rol_agente';
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.clientes TO 'rol_agente';
GRANT SELECT, INSERT ON inmobiliaria_db.contratos TO 'rol_agente';
GRANT SELECT ON inmobiliaria_db.agentes TO 'rol_agente';
GRANT SELECT ON inmobiliaria_db.historial_estados_propiedad TO 'rol_agente';
 
GRANT SELECT, INSERT ON inmobiliaria_db.pagos TO 'rol_contador';
GRANT SELECT ON inmobiliaria_db.contratos TO 'rol_contador';
GRANT SELECT ON inmobiliaria_db.reportes_pagos_pendientes TO 'rol_contador';
 
GRANT EXECUTE ON inmobiliaria_db.* TO 'rol_agente', 'rol_contador';
 
CREATE USER IF NOT EXISTS 'admin_maria'@'localhost' IDENTIFIED BY 'CambiarPassword123!';
CREATE USER IF NOT EXISTS 'agente_juan'@'localhost' IDENTIFIED BY 'CambiarPassword123!';
CREATE USER IF NOT EXISTS 'contador_luis'@'localhost' IDENTIFIED BY 'CambiarPassword123!';
 
GRANT 'rol_administrador' TO 'admin_maria'@'localhost';
GRANT 'rol_agente' TO 'agente_juan'@'localhost';
GRANT 'rol_contador' TO 'contador_luis'@'localhost';
 
SET DEFAULT ROLE ALL TO 'admin_maria'@'localhost', 'agente_juan'@'localhost', 'contador_luis'@'localhost';
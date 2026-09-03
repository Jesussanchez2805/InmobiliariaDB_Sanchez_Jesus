-- ---------------------------------------------------------------------
-- Optimización e INDICES
-- ---------------------------------------------------------------------
CREATE INDEX idx_propiedades_estado ON propiedades(estado);
CREATE INDEX idx_propiedades_tipo   ON propiedades(id_tipo);
CREATE INDEX idx_contratos_estado_tipo ON contratos(estado, tipo_contrato);
CREATE INDEX idx_contratos_propiedad   ON contratos(id_propiedad);
CREATE INDEX idx_pagos_contrato_mes    ON pagos(id_contrato, mes_correspondiente);
 
 -- EJEMPLO
 
EXPLAIN SELECT c.id_contrato, cl.nombre, fn_calcular_deuda_pendiente(c.id_contrato) AS deuda
FROM contratos c
JOIN clientes cl ON cl.id_cliente = c.id_cliente
WHERE c.tipo_contrato = 'arriendo' AND c.estado = 'activo';



 -- ---------------------------------------------------------------------
-- EVENTO PROGRAMADO MENSUAL
-- ---------------------------------------------------------------------
SET GLOBAL event_scheduler = ON;
 
DELIMITER $$
 
CREATE EVENT evt_reporte_mensual_pagos_pendientes
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-10-01 06:00:00'
DO
BEGIN
    INSERT INTO reportes_pagos_pendientes (id_contrato, id_propiedad, id_cliente, deuda_pendiente)
    SELECT c.id_contrato, c.id_propiedad, c.id_cliente,
           fn_calcular_deuda_pendiente(c.id_contrato)
    FROM contratos c
    WHERE c.tipo_contrato = 'arriendo'
      AND c.estado = 'activo'
      AND fn_calcular_deuda_pendiente(c.id_contrato) > 0;
END$$
 
DELIMITER ;
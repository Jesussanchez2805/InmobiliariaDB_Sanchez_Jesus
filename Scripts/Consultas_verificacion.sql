-- ---------------------------------------------------------------------
-- CONSULTAS DE VERIFICACIÓN
-- ---------------------------------------------------------------------
 
-- Comisión del agente en la venta (contrato 1)
SELECT fn_calcular_comision(1) AS comision_venta;
 
-- Deuda pendiente del contrato de arriendo (contrato 2)
SELECT fn_calcular_deuda_pendiente(2) AS deuda_pendiente;
 
-- Propiedades disponibles por tipo
SELECT nombre_tipo, fn_total_disponibles_por_tipo(id_tipo) AS disponibles
FROM tipos_propiedad;
 
-- Historial de cambios de estado generado automáticamente
SELECT * FROM historial_estados_propiedad;
 
-- Auditoría de contratos generada automáticamente
SELECT * FROM auditoria_contratos;
 
-- Consulta optimizada (usa idx_contratos_estado_tipo)
EXPLAIN SELECT c.id_contrato, cl.nombre, fn_calcular_deuda_pendiente(c.id_contrato) AS deuda
FROM contratos c
JOIN clientes cl ON cl.id_cliente = c.id_cliente
WHERE c.tipo_contrato = 'arriendo' AND c.estado = 'activo';
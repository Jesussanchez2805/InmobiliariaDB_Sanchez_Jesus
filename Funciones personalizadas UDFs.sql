-- ---------------------------------------------------------------------
-- Funciones personalizadas (UDFs) para operaciones clave
-- ---------------------------------------------------------------------
 
 -- ---------------------------------------------------------------------
-- Calcular comisión de un agente en una venta
-- ---------------------------------------------------------------------
 
DELIMITER $$
 
CREATE FUNCTION fn_calcular_comision(p_id_contrato INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_valor_total DECIMAL(14,2);
    DECLARE v_porcentaje DECIMAL(5,2);
    DECLARE v_tipo_contrato VARCHAR(20);
 
    SELECT c.valor_total, a.porcentaje_comision, c.tipo_contrato
    INTO v_valor_total, v_porcentaje, v_tipo_contrato
    FROM contratos c
    JOIN agentes a ON a.id_agente = c.id_agente
    WHERE c.id_contrato = p_id_contrato;
 
    IF v_tipo_contrato <> 'venta' THEN
        RETURN 0.00;
    END IF;
 
    RETURN ROUND(v_valor_total * (v_porcentaje / 100), 2);
END$$
 
-- ---------------------------------------------------------------------
-- Calcular deuda pendiente en contratos de arriendo.
-- ---------------------------------------------------------------------
 
 
CREATE FUNCTION fn_calcular_deuda_pendiente(p_id_contrato INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_valor_mensual DECIMAL(12,2);
    DECLARE v_fecha_inicio DATE;
    DECLARE v_tipo VARCHAR(20);
    DECLARE v_meses_transcurridos INT;
    DECLARE v_total_esperado DECIMAL(14,2);
    DECLARE v_total_pagado DECIMAL(14,2);
 
    SELECT valor_mensual, fecha_inicio, tipo_contrato
    INTO v_valor_mensual, v_fecha_inicio, v_tipo
    FROM contratos
    WHERE id_contrato = p_id_contrato;
 
    IF v_tipo <> 'arriendo' THEN
        RETURN 0.00;
    END IF;
 
    SET v_meses_transcurridos = TIMESTAMPDIFF(MONTH, v_fecha_inicio, CURDATE()) + 1;
    SET v_total_esperado = v_meses_transcurridos * v_valor_mensual;
 
    SELECT IFNULL(SUM(valor_pagado), 0) INTO v_total_pagado
    FROM pagos WHERE id_contrato = p_id_contrato;
 
    RETURN GREATEST(v_total_esperado - v_total_pagado, 0);
END$$

 
-- ---------------------------------------------------------------------
-- Obtener total de propiedades disponibles por tipo.
-- ---------------------------------------------------------------------

 
CREATE FUNCTION fn_total_disponibles_por_tipo(p_id_tipo INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total
    FROM propiedades
    WHERE id_tipo = p_id_tipo AND estado = 'disponible';
    RETURN v_total;
END$$
 
DELIMITER ;
-- ---------------------------------------------------------------------
-- TRIGGERS DE AUDITORÍA
-- ---------------------------------------------------------------------
 
DELIMITER $$
 
-- ---------------------------------------------------------------------
-- Cambio de estado de una propiedad.
-- ---------------------------------------------------------------------
 
CREATE TRIGGER trg_propiedad_cambio_estado
AFTER UPDATE ON propiedades
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO historial_estados_propiedad (id_propiedad, estado_anterior, estado_nuevo, usuario_bd)
        VALUES (NEW.id_propiedad, OLD.estado, NEW.estado, CURRENT_USER());
    END IF;
END$$

 -- ---------------------------------------------------------------------
-- Registro de un nuevo contrato.
-- ---------------------------------------------------------------------
 
CREATE TRIGGER trg_nuevo_contrato_auditoria
AFTER INSERT ON contratos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_contratos (id_contrato, accion, detalle, usuario_bd)
    VALUES (NEW.id_contrato, 'CREACION',
            CONCAT('Contrato de ', NEW.tipo_contrato, ' por valor ', NEW.valor_total),
            CURRENT_USER());
 
    IF NEW.tipo_contrato = 'venta' THEN
        UPDATE propiedades SET estado = 'vendida' WHERE id_propiedad = NEW.id_propiedad;
    ELSEIF NEW.tipo_contrato = 'arriendo' THEN
        UPDATE propiedades SET estado = 'arrendada' WHERE id_propiedad = NEW.id_propiedad;
    END IF;
END$$
 
DELIMITER ;
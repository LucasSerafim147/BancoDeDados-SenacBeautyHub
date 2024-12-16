DELIMITER $$
-- Trigger 1: Registrar data de criação em 'usuario'
CREATE TRIGGER before_insert_usuario
BEFORE INSERT ON `usuario`
FOR EACH ROW
BEGIN
    SET NEW.dataNasc = IFNULL(NEW.dataNasc, CURDATE());
END$$

INSERT INTO usuario (nome, email) VALUES ('João Silva', 'joao@email.com');

DELIMITER $$
-- Trigger 2: Garantir telefone único por usuário
CREATE TRIGGER before_insert_telefone
BEFORE INSERT ON `telefone`
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM `telefone` WHERE numero = NEW.numero AND usuario_idUsuario = NEW.usuario_idUsuario
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O número de telefone já está registrado para este usuário.';
    END IF;
END$$

DELIMITER $$
-- Trigger 3: Garantir relação válida entre cliente e usuário
CREATE TRIGGER before_insert_cliente
BEFORE INSERT ON `cliente`
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM `usuario` WHERE idUsuario = NEW.usuario_idUsuario
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Usuário associado ao cliente não existe.';
    END IF;
END$$

DELIMITER $$
-- Trigger 4: Atualizar log após alteração em 'alteracao'
CREATE TRIGGER after_insert_alteracao
AFTER INSERT ON `alteracao`
FOR EACH ROW
BEGIN
    INSERT INTO `log_alteracoes` (`idalteracao`, `dataAlteracao`, `descricao`)
    VALUES (NEW.idalteracao, NEW.dataAlteracao, CONCAT('Alteração de serviço: ', NEW.novoServico));
END$$

DELIMITER $$
-- Trigger 5: Impedir agendamentos duplicados -- DEU CERTO EM
CREATE TRIGGER before_insert_agendamento
BEFORE INSERT ON `agendamento`
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM `agendamento` WHERE data = NEW.data AND hora = NEW.hora
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Já existe um agendamento para esta data e hora.';
    END IF;
END$$

DELIMITER $$
-- Trigger 6: Calcular preço total em 'servicos_has_agendamento'
CREATE TRIGGER after_insert_servicos_has_agendamento
AFTER INSERT ON `servicos_has_agendamento`
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(preco) INTO total
    FROM `servicos`
    WHERE idservicos = NEW.servicos_idservicos;
    UPDATE `agendamento`
    SET totalPreco = total
    WHERE idagendamento = NEW.agendamento_idagendamento;
END$$

DELIMITER $$
-- Trigger 7: Verificar se especialista está disponível -- DEU CERTO EM
CREATE TRIGGER before_insert_Disponibilidade
BEFORE INSERT ON `Disponibilidade`
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM `Disponibilidade` 
        WHERE data = NEW.data AND hora = NEW.hora AND especialista_idespecialista = NEW.especialista_idespecialista
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Especialista já está ocupado nesse horário.';
    END IF;
END$$

DELIMITER $$
-- Trigger 8: Atualizar tabela de serviços após remoção de um agendamento
CREATE TRIGGER after_delete_agendamento
AFTER DELETE ON `agendamento`
FOR EACH ROW
BEGIN
    DELETE FROM `servicos_has_agendamento`
    WHERE agendamento_idagendamento = OLD.idagendamento;
END$$

DELIMITER $$
-- Trigger 9: Atualizar total de agendamentos por administrador
CREATE TRIGGER after_insert_agendamento_count
AFTER INSERT ON `agendamento`
FOR EACH ROW
BEGIN
    UPDATE `administrador`
    SET totalAgendamentos = (SELECT COUNT(*) FROM `agendamento` WHERE administrador_idadministrador = NEW.administrador_idadministrador)
    WHERE idadministrador = NEW.administrador_idadministrador;
END$$

DELIMITER $$
-- Trigger 10: Bloquear exclusão de usuários com agendamentos ativos ESSE DEU CERTO EM
CREATE TRIGGER before_delete_usuario
BEFORE DELETE ON `usuario`
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM `agendamento` WHERE administrador_usuario_idUsuario = OLD.idUsuario
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Usuário não pode ser excluído enquanto possuir agendamentos ativos.';
    END IF;
END$$

CREATE TRIGGER after_insert_agendamento_log
AFTER INSERT ON `agendamento`
FOR EACH ROW
BEGIN
    INSERT INTO `log_agendamentos` (`mensagem`, `dataRegistro`)
    VALUES (CONCAT('Agendamento criado: Data - ', NEW.data, ', Hora - ', NEW.hora), NOW());
END;


DELIMITER ;

select * from disponibilidade;
INSERT INTO Disponibilidade (data, hora, especialista_idespecialista,especialista_usuario_idUsuario) 
VALUES ('2024-12-13', '09:00:00', 1,2);



insert into agendamento values('1', '2024-01-01', '10:00:00', '1', '3');








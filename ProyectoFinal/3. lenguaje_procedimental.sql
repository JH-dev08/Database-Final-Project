-- // REALIZADO POR: Andrés Cardenas 010, José Herrera 001 y Jader Morales 028
SET SERVEROUTPUT ON;
-- =============================================================================
-- 2. BLOQUES PL/SQL (0.3)
-- =============================================================================
-- 2.1 Declaración y uso de variables - UN bloque anonimo    
-- =============================================================================
DECLARE
    v_nombre_sistema CONSTANT VARCHAR2(30) := 'MediClinic SQL v1.0';
    v_total_personas  NUMBER;
    v_fecha_ejecucion DATE := SYSDATE;
BEGIN
    SELECT COUNT(*) INTO v_total_personas FROM PERSONA;
    
    DBMS_OUTPUT.PUT_LINE('=== SISTEMA: ' || v_nombre_sistema || ' ===');
    DBMS_OUTPUT.PUT_LINE('Fecha de Reporte: ' || TO_CHAR(v_fecha_ejecucion, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Total de usuarios registrados en la plataforma: ' || v_total_personas);
END;
/

-- =============================================================================
-- 2.2 Bloque anónimo con recuperación de información
-- =============================================================================
DECLARE
    v_doc_identificacion PERSONA.NUM_DOCUMENTO%TYPE;
    v_nombre_completo    PERSONA.NOMBRE_APELLIDO%TYPE;
    v_correo_elec        PERSONA.CORREO_ELECTRONICO%TYPE;
BEGIN
    -- Selecciona la primera persona que encuentre para demostrar la recuperación
    SELECT NUM_DOCUMENTO, NOMBRE_APELLIDO, CORREO_ELECTRONICO
    INTO   v_doc_identificacion, v_nombre_completo, v_correo_elec
    FROM   PERSONA
    WHERE  ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('=== INFORMACIÓN DE USUARIO RECONOCIDO ===');
    DBMS_OUTPUT.PUT_LINE('Documento: ' || v_doc_identificacion);
    DBMS_OUTPUT.PUT_LINE('Nombre   : ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('Contacto : ' || NVL(v_correo_elec, 'Sin correo electrónico registrado'));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: No existen registros en la tabla PERSONA actualmente.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- =============================================================================
-- 3. ESTRUCTURAS DE CONTROL Y CURSORES (0.3)
-- =============================================================================
-- 3.1 Estructuras condicionales | Condicional para saber a que categoria de persona pertenece un paciente por su EDAD
-- =================================================================
DECLARE
    v_nombre_paciente   PERSONA.nombre_apellido%TYPE;
    v_edad       NUMBER;
    v_fecha_nac  PERSONA.FECHA_NACIMIENTO%TYPE;
    v_categoria  VARCHAR2(20);
    p_num_documento CONSTANT PERSONA.NUM_DOCUMENTO%TYPE := 711221338;

BEGIN
    SELECT p.NOMBRE_APELLIDO, FECHA_NACIMIENTO
    INTO   v_nombre_paciente, v_fecha_nac
    FROM   PERSONA p
    JOIN   PACIENTE pa ON pa.FK_NUM_DOCUMENTO = p.NUM_DOCUMENTO
    WHERE  NUM_DOCUMENTO = p_num_documento;

    -- Calcular edad exacta en anos cumplidos
    v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);

    IF v_edad IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Error: Edad no valida.');
    END IF;

    -- Clasificar segun rango etario SGSSS
    IF    v_edad BETWEEN 0  AND 11 THEN v_categoria := 'PEDIATRICO';
    ELSIF v_edad BETWEEN 12 AND 17 THEN v_categoria := 'ADOLESCENTE';
    ELSIF v_edad BETWEEN 18 AND 39 THEN v_categoria := 'ADULTO JOVEN';
    ELSIF v_edad BETWEEN 40 AND 59 THEN v_categoria := 'ADULTO';
    ELSE                                v_categoria := 'ADULTO MAYOR';
    END IF;
    DBMS_OUTPUT.PUT_LINE('=== Paciente con nombre "' || v_nombre_paciente || '" pertenece a la categoria "' || v_categoria || '" ===');
    DBMS_OUTPUT.PUT_LINE('Nacido/a el ' || TO_CHAR(v_fecha_nac, 'DD/MM/YYYY') || ' y actualmente con ' || v_edad || ' años.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró al paciente con documento ' || p_num_documento || ' en la base de datos.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
END;
/

-- =================================================================
-- 3.2 Estructuras repetitivas (minimo DOS ciclos diferentes) | LOOP - WHILE LOOP - FOR LOOP
-- =================================================================
-- A) CICLO 1: FOR LOOP - Control de Alerta de Stock Crítico de Medicinas
-- =================================================================
DECLARE
    v_umbral_critico CONSTANT INT := 10;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== REPORTE AUTOMÁTICO DE STOCK CRÍTICO (FOR LOOP) ===');
    
    -- El ciclo FOR maneja implícitamente la apertura y cierre del cursor
    FOR reg_medicina IN (SELECT NOMBRE_COMERCIAL, ID_MEDICINA, PRESENTACION, STOCK FROM MEDICINA WHERE STOCK < v_umbral_critico) LOOP
        DBMS_OUTPUT.PUT_LINE('¡ALERTA! El medicamento "' || reg_medicina.NOMBRE_COMERCIAL || '" (' || reg_medicina.ID_MEDICINA || ') está por agotarse. Stock actual: ' || reg_medicina.STOCK);
    END LOOP;
END;
/

-- PRUEBA DE INSERCION
/*
DECLARE
     p_id_medicina       MEDICINA.ID_MEDICINA%TYPE;
    v_nuevo_med_num     NUMBER;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(ID_MEDICINA, 4))), 0) + 1
    INTO   v_nuevo_med_num
    FROM   MEDICINA;
    p_id_medicina := 'MED' || LPAD(v_nuevo_med_num, 3, '0');
    
    INSERT INTO MEDICINA VALUES (p_id_medicina, 'PRUEBA', 'Acetaminofen', '500mg', 'Tabletas', 9);
END;
/
*/

-- =================================================================
-- B) CICLO 2: WHILE LOOP - Simulación de Depuración/Listado de Licencias Médicas
-- =================================================================
DECLARE
    CURSOR c_licencias IS 
        SELECT d.ID_DOCTOR, p.NOMBRE_APELLIDO, d.NUMERO_LICENCIA 
        FROM DOCTOR d 
        JOIN PERSONA p ON d.FK_NUM_DOCUMENTO = p.NUM_DOCUMENTO;
        
    v_id_doc      DOCTOR.ID_DOCTOR%TYPE;
    v_nom_doc     PERSONA.NOMBRE_APELLIDO%TYPE;
    v_licencia    DOCTOR.NUMERO_LICENCIA%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== VERIFICACIÓN DE LICENCIAS VIGENTES (WHILE LOOP) ===');
    OPEN c_licencias;
    FETCH c_licencias INTO v_id_doc, v_nom_doc, v_licencia;
    
    WHILE c_licencias%FOUND LOOP
        DBMS_OUTPUT.PUT_LINE('Doctor ID: ' || v_id_doc || ' | Profesional: ' || v_nom_doc || ' | Licencia No: ' || v_licencia);
        FETCH c_licencias INTO v_id_doc, v_nom_doc, v_licencia;
    END LOOP;
    
    CLOSE c_licencias;
END;
/

-- =================================================================
-- 3.3 Cursores y manejo de excepciones. (CHECK)
-- CURSOR QUE RECORRE LA TABLA DE PACIENES ATENDIDOS POR UN ID_DOCTOR EN ESPECIFICO Y LOS MUESTRA POR FECHA DE CONSULTA ASCENDENTE
-- =================================================================
DECLARE     
    v_doctor_buscado        DOCTOR.ID_DOCTOR%TYPE := 'DOC0006';
    v_contador_pacientes    NUMBER := 0;
    v_verificar_control     NUMBER;

    CURSOR c_pacientes_por_doctor (p_id_doctor VARCHAR2) IS
        SELECT pa.ID_PACIENTE,
            p.NOMBRE_APELLIDO,
            p.FECHA_NACIMIENTO,
            p.SEXO,
            p.DIRECCION,
            p.CORREO_ELECTRONICO,
            p.TIPO_SANGRE,
            c.FECHA_HORA
        FROM PERSONA p
        JOIN PACIENTE pa        ON p.NUM_DOCUMENTO = pa.FK_NUM_DOCUMENTO
        JOIN HISTORIA_CLINICA h ON pa.ID_PACIENTE = h.FK_ID_PACIENTE
        JOIN CONSULTA c         ON h.ID_HISTORIA = c.FK_ID_HISTORIA
        JOIN DOCTOR d           ON d.ID_DOCTOR = c.FK_ID_DOCTOR
        WHERE d.ID_DOCTOR = p_id_doctor
        ORDER BY c.FECHA_HORA ASC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== EVALUANDO DATOS DEL DOCTOR: ' || v_doctor_buscado || ' ===');
    
    -- Validación 1: Forzar NO_DATA_FOUND si el código de doctor no existe en DOCTOR
    SELECT 1 INTO v_verificar_control 
    FROM DOCTOR 
    WHERE ID_DOCTOR = v_doctor_buscado;
    
    -- Validación 2: Forzar TOO_MANY_ROWS (Ejemplo de control: Validar que el doctor no tenga 
    -- asignaciones duplicadas en la tabla, si devuelve más de 1 arroja el error)
    SELECT 1 INTO v_verificar_control
    FROM DOCTOR
    WHERE ID_DOCTOR = v_doctor_buscado
      AND ROWNUM <= 2;
      
    -- RECORRIDO DEL CURSOR SI LAS VALIDACIONES PASAN
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
    FOR v IN c_pacientes_por_doctor(v_doctor_buscado) LOOP
        DBMS_OUTPUT.PUT_LINE('- Paciente ID:    ' || v.ID_PACIENTE);
        DBMS_OUTPUT.PUT_LINE('- Nombre:         ' || v.NOMBRE_APELLIDO);
        DBMS_OUTPUT.PUT_LINE('- Fecha Nacido:   ' || TO_CHAR(v.FECHA_NACIMIENTO, 'DD/MM/YYYY'));
        DBMS_OUTPUT.PUT_LINE('- Sexo:           ' || v.SEXO);
        DBMS_OUTPUT.PUT_LINE('- E-mail:         ' || v.CORREO_ELECTRONICO);
        DBMS_OUTPUT.PUT_LINE('- Tipo de sangre: ' || v.TIPO_SANGRE);
        DBMS_OUTPUT.PUT_LINE('- Fecha de Atencion: ' || TO_CHAR(v.FECHA_HORA,'DD/MM/YYYY'));
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
        v_contador_pacientes := v_contador_pacientes + 1;
    END LOOP;

    IF v_contador_pacientes = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: El doctor existe pero no registra pacientes atendidos.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TOTAL DE PACIENTES REGISTRADOS: ' || v_contador_pacientes);
    END IF;
    
-- MANEJO DE EXCEPCIONES SOLICITADAS
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR CRÍTICO: El identificador de doctor "' || v_doctor_buscado || '" no existe en el sistema.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR CRÍTICO: Inconsistencia detectada. Se encontraron múltiples registros activos para el doctor ' || v_doctor_buscado || '.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO: ' || SQLERRM);
END;
/

-- =============================================================================
-- 4. PROCEDIMIENTOS, FUNCIONES Y TRIGGERS (0.4)
-- =============================================================================
-- 4.1 Procedimientos almacenados.  |  Crear minimo DOS procedimientos almacenados (CHECK)
-- =================================================================
-- A)  PROCEDIMIENTO ALMACENADO 1
-- PERSONAS AFECTADAS POR LA SUBIDA DEL COSTO en un 20% DE UNA CONSULTA EN LA CUAL SE RECETO UN MEDICAMENTO (ID_MEDICINA)
-- =================================================================
CREATE OR REPLACE PROCEDURE SP_CAMBIO_COSTO_POR_MEDICINA (
    p_id_medicina IN MEDICINA.ID_MEDICINA%TYPE
) AS
    fecha_cambio            DATE := SYSDATE;
    aumento                 CONSTANT CONSULTA.COSTO%TYPE := 1.20;
    v_pacientes_afectados   NUMBER := 0;
    v_existe_medicina       NUMBER;
BEGIN   
    DBMS_OUTPUT.PUT_LINE('=== INICIO DE REPORTE DE AFECTADOS - '|| TO_CHAR(fecha_cambio, 'DD/MM/YYYY')||' ===');
    
    -- VALIDACIÓN: Forzar NO_DATA_FOUND si la medicina no existe en el catálogo básico
    SELECT 1 INTO v_existe_medicina 
    FROM MEDICINA 
    WHERE ID_MEDICINA = p_id_medicina;

    -- El bucle FOR muestra la vista previa de lo que se va a modificar
    FOR v IN (
        SELECT
            h.ID_HISTORIA,
            p.NOMBRE_APELLIDO, 
            p.CORREO_ELECTRONICO,
            m.NOMBRE_COMERCIAL AS MEDICAMENTO_RECETADO,
            c.COSTO
        FROM PERSONA p
        JOIN PACIENTE pa        ON p.NUM_DOCUMENTO = pa.FK_NUM_DOCUMENTO
        JOIN HISTORIA_CLINICA h ON pa.ID_PACIENTE = h.FK_ID_PACIENTE
        JOIN CONSULTA c         ON h.ID_HISTORIA = c.FK_ID_HISTORIA
        JOIN RECETA r           ON c.ID_CONSULTA = r.FK_ID_CONSULTA
        JOIN MEDICINA m         ON m.ID_MEDICINA = r.FK_ID_MEDICINA
        WHERE m.ID_MEDICINA = p_id_medicina
    ) LOOP
        
        DBMS_OUTPUT.PUT_LINE('- Historia ID:   ' || v.ID_HISTORIA);
        DBMS_OUTPUT.PUT_LINE('- Nombre:        ' || v.NOMBRE_APELLIDO);
        DBMS_OUTPUT.PUT_LINE('- Correo:        ' || v.CORREO_ELECTRONICO);
        DBMS_OUTPUT.PUT_LINE('- Med. recetada: ' || v.MEDICAMENTO_RECETADO);
        DBMS_OUTPUT.PUT_LINE('- Costo Actual:  ' || v.COSTO || ' | Costo Nuevo (+20%): ' || (v.COSTO * aumento));
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
        
        v_pacientes_afectados := v_pacientes_afectados + 1;
    END LOOP;
    
    -- =================================================================
    -- APLICACIÓN DE CAMBIOS EN LA BASE DE DATOS
    -- =================================================================
    IF v_pacientes_afectados = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No se encontraron registros para modificar de la medicina ' || p_id_medicina || '.');
    ELSE
        -- Ejecutamos la actualización en la tabla CONSULTA
        UPDATE CONSULTA c
        SET c.COSTO = c.COSTO * aumento
        WHERE c.ID_CONSULTA IN (
            SELECT r.FK_ID_CONSULTA 
            FROM RECETA r 
            WHERE r.FK_ID_MEDICINA = p_id_medicina
        );
        
        -- SQL%ROWCOUNT nos confirma cuántas filas físicas se actualizaron en el UPDATE
        DBMS_OUTPUT.PUT_LINE('TOTAL DE REGISTROS EVALUADOS: ' || v_pacientes_afectados);
        DBMS_OUTPUT.PUT_LINE('ÉXITO: Se han actualizado ' || SQL%ROWCOUNT || ' consultas en la base de datos.');
        
        COMMIT; -- Guardamos los cambios permanentemente
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró la medicina ' || p_id_medicina || ' en la base de datos.');
        ROLLBACK;
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error: La medicina ' || p_id_medicina || ' generó una inconsistencia de múltiples filas duplicadas.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK; -- Deshace cualquier cambio intermedio si ocurre una falla física
END SP_CAMBIO_COSTO_POR_MEDICINA;
/

-- =================================================================
-- B)  PROCEDIMIENTO ALMACENADO 2
-- REGISTRAR UNA NUEVA CONSULTA DE UN PACIENTE ANEXADO A BASE DE DATOS
-- =================================================================
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_NUEVA_CONSULTA (
    p_id_paciente  IN  PACIENTE.ID_Paciente%TYPE,
    p_id_doctor    IN  DOCTOR.ID_Doctor%TYPE,
    p_fecha_hora   IN  CONSULTA.Fecha_Hora%TYPE,
    p_motivo       IN  CONSULTA.Motivo%TYPE,
    p_sintomas     IN  CONSULTA.Sintomas_Actuales%TYPE,
    p_diagnostico  IN  CONSULTA.Diagnostico%TYPE,
    p_plan         IN  CONSULTA.Plan_Terapeutico%TYPE,
    p_costo        IN  CONSULTA.Costo%TYPE,
    p_id_medicina  IN  MEDICINA.ID_Medicina%TYPE  DEFAULT NULL,
    p_dosis        IN  RECETA.Dosis%TYPE          DEFAULT NULL,
    p_duracion     IN  RECETA.Duracion%TYPE       DEFAULT NULL,
    p_id_consulta  OUT CONSULTA.ID_Consulta%TYPE
)
IS
    v_cont          NUMBER := 0;
    v_id_historia    HISTORIA_CLINICA.ID_Historia%TYPE;
    v_nuevo_con_num  NUMBER;
    v_nuevo_rec_num  NUMBER;
    v_id_receta      RECETA.ID_Receta%TYPE;

BEGIN
    -- Validar que el paciente exista en PACIENTE.
    SELECT COUNT(*)
    INTO   v_cont
    FROM   PACIENTE
    WHERE  ID_Paciente = p_id_paciente;

    IF v_cont = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'El paciente "' || p_id_paciente || '" no existe en el sistema.'
        );
    END IF;

    -- Validar que el doctor exista en DOCTOR.
    SELECT COUNT(*)
    INTO   v_cont
    FROM   DOCTOR
    WHERE  ID_Doctor = p_id_doctor;

    IF v_cont = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20011,
            'El doctor "' || p_id_doctor || '" no existe en el sistema.'
        );
    END IF;

    -- Obtener el historial clinico del paciente
    SELECT ID_Historia
    INTO   v_id_historia
    FROM   HISTORIA_CLINICA
    WHERE  FK_ID_Paciente = p_id_paciente;

    -- Validar la medicina si se va a generar receta
    IF p_id_medicina IS NOT NULL THEN

        IF p_dosis IS NULL OR p_duracion IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20014,
                'Si se indica medicina, la dosis y la duracion son obligatorias.'
            );
        END IF;

        SELECT COUNT(*)
        INTO   v_cont
        FROM   MEDICINA
        WHERE  ID_Medicina = p_id_medicina;

        IF v_cont = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20013,
                'La medicina "' || p_id_medicina || '" no existe en el catalogo.'
            );
        END IF;
    END IF;

    -- Generar el nuevo ID de consulta (MAX + 1)
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(ID_Consulta, 4))), 0) + 1
    INTO   v_nuevo_con_num
    FROM   CONSULTA;
    p_id_consulta := 'CON' || LPAD(v_nuevo_con_num, 5, '0');

    -- Insertar la nueva consulta
    INSERT INTO CONSULTA VALUES (
        p_id_consulta, v_id_historia, p_id_doctor, p_fecha_hora,
        p_motivo, p_sintomas, p_diagnostico, p_plan, p_costo
    );

    -- Opcional: Insertar la receta si se proporciono medicina
    IF p_id_medicina IS NOT NULL THEN
        SELECT NVL(MAX(TO_NUMBER(SUBSTR(ID_Receta, 4))), 0) + 1
        INTO   v_nuevo_rec_num
        FROM   RECETA;
        v_id_receta := 'REC' || LPAD(v_nuevo_rec_num, 5, '0');   -- se genera el ID_RECETA

        INSERT INTO RECETA VALUES (
            v_id_receta, p_id_consulta, p_id_medicina,
            p_dosis, p_duracion
        );
    END IF;

    -- Confirmar la transaccion y reportar resultado
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('Consulta registrada correctamente.');
    DBMS_OUTPUT.PUT_LINE('  ID Consulta    : ' || p_id_consulta);
    DBMS_OUTPUT.PUT_LINE('  Paciente       : ' || p_id_paciente);
    DBMS_OUTPUT.PUT_LINE('  Doctor         : ' || p_id_doctor);
    DBMS_OUTPUT.PUT_LINE('  Historia       : ' || v_id_historia);
    DBMS_OUTPUT.PUT_LINE('  Fecha y hora   : ' ||
        TO_CHAR(p_fecha_hora, 'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('  Costo          : $' ||
        TO_CHAR(p_costo, 'FM999,999,990.00'));
    IF p_id_medicina IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('  Receta         : ' || v_id_receta ||
            '  ->  ' || p_id_medicina ||
            ' | ' || p_dosis ||
            ' | ' || p_duracion);
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Receta         : Sin receta');
    END IF;
    DBMS_OUTPUT.PUT_LINE('=========================================');

-- ------------------------------------------------------------------
-- MANEJO DE EXCEPCIONES
-- ------------------------------------------------------------------
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: El paciente "' || p_id_paciente || '" no tiene historial clinico registrado.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
END SP_REGISTRAR_NUEVA_CONSULTA;
/

-- =================================================================
-- 4.2 Funciones almacenadas  | Cree mínimo DOS funciones almacenadas que retornen información útil para el proyecto.
-- Cada funcion debe: a) Recibir parametros   b) Retornar un valor   c) Ser utilizada en una consulta SQL o bloque PL/SQL.
-- =================================================================
-- A)  FUNCION ALMACENADA 1
-- CALCULAR EDAD DE UNA PERSONA
-- =================================================================
CREATE OR REPLACE FUNCTION FN_CALCULAR_EDAD (
    p_num_documento IN PERSONA.NUM_DOCUMENTO%TYPE
)
RETURN NUMBER
IS
    v_fecha_nac  PERSONA.FECHA_NACIMIENTO%TYPE;
    v_edad       NUMBER;

BEGIN
    -- Obtener la fecha de nacimiento de PERSONA
    SELECT FECHA_NACIMIENTO
    INTO   v_fecha_nac
    FROM   PERSONA
    WHERE  NUM_DOCUMENTO = p_num_documento;

    -- Calcular edad exacta en anos cumplidos
    v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);
    RETURN v_edad;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Persona no registrada: retornar NULL sin interrumpir la consulta
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;

END FN_CALCULAR_EDAD;
/

-- =================================================================
-- B)  FUNCION ALMACENADA 2
-- Suma y retorna el costo acumulado de todas las consultas
-- medicas vinculadas al historial clinico de un paciente.
-- =================================================================
CREATE OR REPLACE FUNCTION FN_COSTO_TOTAL_HISTORIAL (
    p_id_paciente IN PACIENTE.ID_Paciente%TYPE
)
RETURN DECIMAL
IS
    v_cont        NUMBER := 0;
    v_id_historia HISTORIA_CLINICA.ID_Historia%TYPE;
    v_total       DECIMAL(10,2) := 0;
BEGIN
    -- Verificar que el paciente exista
    SELECT COUNT(*)
    INTO   v_cont
    FROM   PACIENTE
    WHERE  ID_Paciente = p_id_paciente;

    IF v_cont = 0 THEN
        RETURN NULL;
    END IF;

    -- Obtener el historial clinico del paciente
    SELECT ID_Historia
    INTO   v_id_historia
    FROM   HISTORIA_CLINICA
    WHERE  FK_ID_Paciente = p_id_paciente;

    -- Sumar los costos de todas las consultas del historial
    SELECT NVL(SUM(Costo), 0)
    INTO   v_total
    FROM   CONSULTA
    WHERE  FK_ID_Historia = v_id_historia;

    RETURN v_total;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Sin historial registrado
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;
END FN_COSTO_TOTAL_HISTORIAL;
/

-- =================================================================
-- 4.3 Triggers  |  Cree mínimo DOS triggers relacionados al sistema.
-- =================================================================
-- A)  TRIGGER 1  |  Todos los datos de INSERT, UPDATE o DELETE sobre la
-- tabla CONSULTA queda registrada en la tabla AUDITORIA_CONSULTA
-- =================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_CONSULTA';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -942 THEN NULL;
        ELSE RAISE;
        END IF;
END;
/

CREATE TABLE AUDITORIA_CONSULTA (
    ID_Auditoria      NUMBER GENERATED BY DEFAULT AS IDENTITY,
    Tipo_Operacion    VARCHAR2(10)   NOT NULL,
    ID_Consulta_Ref   VARCHAR2(20),
    Motivo_Ref        VARCHAR2(200),
    Diagnostico_Ant   VARCHAR2(200),
    Diagnostico_Nvo   VARCHAR2(200),
    Costo_Anterior    NUMBER(12, 2),
    Costo_Nuevo       NUMBER(12, 2),
    Fecha_Operacion   DATE           DEFAULT SYSDATE,
    Usuario_BD        VARCHAR2(100)  DEFAULT USER,
    CONSTRAINT PK_AUDITORIA_CONSULTA PRIMARY KEY (ID_Auditoria)
);

CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CONSULTA
    AFTER INSERT OR UPDATE OR DELETE ON CONSULTA
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDITORIA_CONSULTA (
            Tipo_Operacion, ID_Consulta_Ref, Motivo_Ref, Diagnostico_Ant, Diagnostico_Nvo,
            Costo_Anterior, Costo_Nuevo, Fecha_Operacion, Usuario_BD
        ) VALUES (
            'INSERT', :NEW.ID_Consulta, :NEW.Motivo, NULL, :NEW.Diagnostico,
            NULL, :NEW.Costo, SYSDATE, USER
        );
    ELSIF UPDATING THEN
        INSERT INTO AUDITORIA_CONSULTA (
            Tipo_Operacion, ID_Consulta_Ref, Motivo_Ref, Diagnostico_Ant, Diagnostico_Nvo,
            Costo_Anterior, Costo_Nuevo, Fecha_Operacion, Usuario_BD
        ) VALUES (
            'UPDATE', :NEW.ID_Consulta, :NEW.Motivo, :OLD.Diagnostico, :NEW.Diagnostico,
            :OLD.Costo, :NEW.Costo, SYSDATE, USER
        );
    ELSIF DELETING THEN
        INSERT INTO AUDITORIA_CONSULTA (
            Tipo_Operacion, ID_Consulta_Ref, Motivo_Ref, Diagnostico_Ant, Diagnostico_Nvo,
            Costo_Anterior, Costo_Nuevo, Fecha_Operacion, Usuario_BD
        ) VALUES (
            'DELETE', :OLD.ID_Consulta, :OLD.Motivo, :OLD.Diagnostico, NULL,
            :OLD.Costo, NULL, SYSDATE, USER
        );
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TRG_AUDITORIA_CONSULTA EJECUTADO CON EXITO. ===');
END TRG_AUDITORIA_CONSULTA;
/

-- =================================================================
-- B)  TRIGGER 2
-- Se crea una tabla con los cambios hechos en diagnosticos de pacientes
-- actualizando su HISTORIA CLINICA
-- =================================================================
BEGIN 
    EXECUTE IMMEDIATE 'DROP TABLE LOG_ACTUALIZACION_DIAGNOSTICOS'; 
EXCEPTION 
    WHEN OTHERS THEN NULL; 
END;
/

CREATE TABLE LOG_ACTUALIZACION_DIAGNOSTICOS (
    ID_LOG           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Historia      VARCHAR2(10),
    Diagnostico_Prev VARCHAR2(300),
    Diagnostico_Nue  VARCHAR2(300),
    Usuario_DB       VARCHAR2(50) DEFAULT USER,
    Fecha_Log        TIMESTAMP DEFAULT SYSTIMESTAMP
);
/

-- 2. Creación del Trigger Compuesto para evitar Tablas Mutantes (ORA-04091)
CREATE OR REPLACE TRIGGER TRG_LOG_ACTUALIZAR_DIAGNOSTICO
FOR INSERT ON CONSULTA
COMPOUND TRIGGER

    -- Variables de sesión globales para el ámbito del trigger
    v_diag_previos     HISTORIA_CLINICA.Diagnosticos_Previos%TYPE;
    v_id_historia      VARCHAR2(10);
    v_diagnostico      VARCHAR2(300);
    v_nuevo_valor      HISTORIA_CLINICA.Diagnosticos_Previos%TYPE;
    v_cambio_realizado BOOLEAN := FALSE;

    -- PASO 1: Captura de datos a nivel de fila (Row-Level)
    AFTER EACH ROW IS
    BEGIN
        -- Leemos directamente de las pseudo-columnas :NEW (Evita el ORA-00947 / ORA-04091)
        v_id_historia := :NEW.FK_ID_Historia;
        v_diagnostico := :NEW.Diagnostico;

        -- Consultamos de forma segura el estado actual de la historia clínica
        BEGIN
            SELECT NVL(Diagnosticos_Previos, '') INTO v_diag_previos 
            FROM HISTORIA_CLINICA 
            WHERE ID_Historia = v_id_historia;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_diag_previos := ''; -- Si no existe la historia, asumimos vacío
        END;

        -- Validamos si el diagnóstico ya existe en la cadena de texto
        IF INSTR(NVL(v_diag_previos, ' '), v_diagnostico) = 0 THEN
            -- Si es el primer diagnóstico del paciente
            IF v_diag_previos IS NULL OR LENGTH(TRIM(v_diag_previos)) = 0 THEN
                v_nuevo_valor := v_diagnostico;
            ELSE
                -- Si ya tiene diagnósticos, lo concatenamos usando un separador
                v_nuevo_valor := v_diag_previos || ' | ' || v_diagnostico;
            END IF;
            v_cambio_realizado := TRUE;
        ELSE
            v_nuevo_valor := v_diag_previos;
            v_cambio_realizado := FALSE;
        END IF;
    END AFTER EACH ROW;

    -- PASO 2: Aplicación de cambios a nivel de instrucción (Statement-Level)
    AFTER STATEMENT IS
    BEGIN
        IF v_cambio_realizado THEN
            -- 1. Actualizamos la tabla principal del paciente
            UPDATE HISTORIA_CLINICA 
            SET Diagnosticos_Previos = v_nuevo_valor 
            WHERE ID_Historia = v_id_historia;

            -- 2. Insertamos la fila en la tabla de auditoría (Log) con columnas explícitas
            INSERT INTO LOG_ACTUALIZACION_DIAGNOSTICOS 
                (ID_Historia, Diagnostico_Prev, Diagnostico_Nue)
            VALUES 
                (v_id_historia, v_diag_previos, v_nuevo_valor);

            DBMS_OUTPUT.PUT_LINE('Historial actualizado -> ' || v_id_historia || ' | Diagnostico agregado: "' || v_diagnostico || '"');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Historial sin cambio -> ' || v_id_historia || ' | Diagnostico ya registrado: "' || v_diagnostico || '"');
        END IF;
    END AFTER STATEMENT;

END TRG_LOG_ACTUALIZAR_DIAGNOSTICO;
/

-- =================================================================
-- PRUEBAS DE ESTRUCTURAS Y BLOQUES PL/SQL
-- =================================================================
SET SERVEROUTPUT ON;
-- 1. PROCEDIMIENTO ALMACENADO
-- INVOCACION DE PRUEBA FUNCIONAL
BEGIN
    SP_CAMBIO_COSTO_POR_MEDICINA('MED140');
END;
/

-- 2. PROCEDIMIENTO ALMACENADO
-- Agregar una nueva consulta por el procedimiento.
DECLARE
    v_id_consulta CONSULTA.ID_Consulta%TYPE;
BEGIN
    SP_REGISTRAR_NUEVA_CONSULTA(
        p_id_paciente => 'PAC00002',
        p_id_doctor   => 'DOC0003',
        p_fecha_hora  => TO_DATE('2025-06-20 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
        p_motivo      => 'Control general',
        p_sintomas    => 'Cefalea leve y fatiga',
        p_diagnostico => 'Tension arterial elevada',
        p_plan        => 'Medicacion oral y reposo',
        p_costo       => 999990,
        p_id_medicina => 'MED001',
        p_dosis       => '1 cada 8h',
        p_duracion    => '5 dias',
        p_id_consulta => v_id_consulta
    );
    DBMS_OUTPUT.PUT_LINE('ID generado: ' || v_id_consulta);
END;
/
-- Revisa las ultimas N consultas agregadas.
SELECT ID_Consulta, FK_ID_Historia, FK_ID_Doctor,
       TO_CHAR(Fecha_Hora,'DD/MM/YYYY HH24:MI') AS Fecha_Hora,
       Motivo, Diagnostico, Costo
FROM   CONSULTA
WHERE  ID_Consulta IN (
    SELECT ID_Consulta FROM CONSULTA
    ORDER BY TO_NUMBER(SUBSTR(ID_Consulta,4)) DESC          -- TO_NUMBER(SUBSTR(ID_Consulta,4)) recorta las tres primeras letras del ID
    FETCH FIRST 10 ROWS ONLY
);
-- Revisa las ultimas N recetas agregadas.
SELECT r.ID_Receta, r.FK_ID_Consulta, r.FK_ID_Medicina, r.Dosis, r.Duracion
FROM   RECETA r
WHERE  r.ID_Receta IN (
    SELECT ID_Receta FROM RECETA
    ORDER BY TO_NUMBER(SUBSTR(ID_Receta,4)) DESC
    FETCH FIRST 10 ROWS ONLY
);

-- 1. FUNCION ALMACENADA - primeros tres pacientes
SELECT
    p.NUM_DOCUMENTO,
    p.NOMBRE_APELLIDO,
    TO_CHAR(p.FECHA_NACIMIENTO, 'DD/MM/YYYY')   AS FECHA_NACIMIENTO,
    FN_CALCULAR_EDAD(p.NUM_DOCUMENTO)           AS EDAD_CALCULADA
FROM   PERSONA p
WHERE  p.NUM_DOCUMENTO IN (1058612202, 776831247, 704396250)
ORDER BY EDAD_CALCULADA ASC;

-- 2. FUNCION ALMACENADA - Invocacion en consulta SQL: top 10 pacientes por gasto
SELECT
    pa.ID_PACIENTE,
    p.NOMBRE_APELLIDO,
    TO_CHAR(
        FN_COSTO_TOTAL_HISTORIAL(pa.ID_Paciente),
        'FM$999,999,990.00'
    )                                       AS TOTAL_GASTADO
FROM   PACIENTE pa
JOIN   PERSONA  p ON p.NUM_DOCUMENTO = pa.FK_NUM_DOCUMENTO
WHERE pa.ID_PACIENTE IN ('PAC00998', 'PAC00999', 'PAC01000')
ORDER  BY TOTAL_GASTADO DESC;
-- FETCH  FIRST 10 ROWS ONLY;
        
-- 1. TRIGGER ALMACENADO  - Comprueba el funcionamiento del trigger en AFTER INSERT
DECLARE
    v_id_consulta CONSULTA.ID_Consulta%TYPE;
BEGIN
    SP_REGISTRAR_NUEVA_CONSULTA(
        p_id_paciente => 'PAC00002',
        p_id_doctor   => 'DOC0003',
        p_fecha_hora  => SYSDATE,
        p_motivo      => 'Consulta prueba auditoria',
        p_sintomas    => 'Dolor de cabeza persistente',
        p_diagnostico => 'Migrania tensional',
        p_plan        => 'Analgesicos y reposo',
        p_costo       => 130000,
        p_id_medicina => 'MED001',
        p_dosis       => '1 cada 8h',
        p_duracion    => '5 dias',
        p_id_consulta => v_id_consulta
    );
    DBMS_OUTPUT.PUT_LINE('ID generado: ' || v_id_consulta);
END;
/

-- ====== PERSONA DE PRUEBAS =======
INSERT INTO PERSONA VALUES (1042851710, 'CC', 'Rafael Jose Orozco', TO_DATE('2006-07-08', 'YYYY-MM-DD'), 'M', 'Calle 58 #66-32, Modelo, Barranquilla', 3043784333, 'rafa.orozco@hotmail.com', 'Soltero', 'O+', 'PACIENTE');
DECLARE
    v_id_paciente PACIENTE.ID_PACIENTE%TYPE;
    v_nuevo_pac_num NUMBER;
    v_id_historia HISTORIA_CLINICA.ID_HISTORIA%TYPE;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(ID_PACIENTE, 4))), 0) + 1
    INTO   v_nuevo_pac_num
    FROM   PACIENTE;
    v_id_paciente := 'PAC' || LPAD(v_nuevo_pac_num, 5, '0');
    
    INSERT INTO PACIENTE VALUES (v_id_paciente, 1042851710, 'Ninguna', 'PACIENTE');
    DBMS_OUTPUT.PUT_LINE('ID PACIENTE generado: ' || v_id_paciente);
    
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(ID_HISTORIA, 4))), 0) + 1
    INTO   v_nuevo_pac_num
    FROM   HISTORIA_CLINICA;
    v_id_historia := 'HC' || LPAD(v_nuevo_pac_num, 5, '0');
    
    INSERT INTO HISTORIA_CLINICA VALUES (v_id_historia, v_id_paciente, 'Obesidad grado I', 'Acaros y polvo', 'Artrosis leve', 'Manejo ambulatorio');
    DBMS_OUTPUT.PUT_LINE('ID HISTORIA generado: ' || v_id_historia);
END;
/

-- 2. TRIGGER ALMACENADO
-- Revisamos Diagnosticos previos.
SELECT
    hc.ID_Historia,
    hc.FK_ID_Paciente,
    hc.Diagnosticos_Previos   AS Diagnosticos_Antes
FROM   HISTORIA_CLINICA hc
WHERE  hc.ID_Historia = 'HC01001';  -- PERSONA PRUEBA

-- Generamos una nueva consulta
DECLARE
    v_id_consulta CONSULTA.ID_Consulta%TYPE;
BEGIN
    SP_REGISTRAR_NUEVA_CONSULTA(
        p_id_paciente => 'PAC01001',
        p_id_doctor   => 'DOC0003',
        p_fecha_hora  => SYSDATE,
        p_motivo      => 'Consulta prueba auditoria',
        p_sintomas    => 'Dolor en columna cronico',
        p_diagnostico => 'Artrosis.',
        p_plan        => 'Ejercicio.',
        p_costo       => 9900000,
        p_id_medicina => 'MED006',
        p_dosis       => '1 cada 8h',
        p_duracion    => '20 dias',
        p_id_consulta => v_id_consulta
    );
    DBMS_OUTPUT.PUT_LINE('ID generado: ' || v_id_consulta);
END;
/
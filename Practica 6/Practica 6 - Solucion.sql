
---------------------------------------------{  PRACTICA 6  }---------------------------------------------------------

-- Caso 1)

DECLARE
    CURSOR CUR_MORA_PAC IS
        SELECT P.PAC_RUN,
               P.DV_RUN,
               P.PNOMBRE || ' ' || P.SNOMBRE || ' ' || P.APATERNO || ' ' || P.AMATERNO AS NOM_PACIENTE,
               PA.ATE_ID,
               TRUNC(MONTHS_BETWEEN(SYSDATE, P.FECHA_NACIMIENTO) / 12) AS EDAD_PAC,
               A.FECHA_ATENCION,
               PA.FECHA_VENC_PAGO,
               PA.FECHA_PAGO,
               PA.FECHA_PAGO - PA.FECHA_VENC_PAGO AS DIAS_MOROS,
               E.NOMBRE ESPECIALIDAD
        FROM PACIENTE P
        JOIN ATENCION A        ON (A.PAC_RUN = P.PAC_RUN)
        JOIN PAGO_ATENCION PA  ON (PA.ATE_ID = A.ATE_ID)
        JOIN ESPECIALIDAD E    ON (E.ESP_ID = A.ESP_ID)
        WHERE PA.FECHA_PAGO > PA.FECHA_VENC_PAGO
        AND EXTRACT(YEAR FROM PA.FECHA_VENC_PAGO) = EXTRACT(YEAR FROM SYSDATE) - 1
        ORDER BY PA.FECHA_VENC_PAGO, P.APATERNO;
        
    REG_CURSOR     CUR_MORA_PAC%ROWTYPE;
    REG_PAGO_MORO  PAGO_MOROSO%ROWTYPE;
    V_PORC_DESC    NUMBER(2); 
    
BEGIN
    -- Truncar la tabla PAGO_MOROSO en tiempo de ejecución
    EXECUTE IMMEDIATE('TRUNCATE TABLE PAGO_MOROSO');
    
    OPEN CUR_MORA_PAC;
    
    LOOP
        FETCH CUR_MORA_PAC INTO REG_CURSOR;
        
        REG_PAGO_MORO.MONTO_MULTA :=
        CASE 
            WHEN REG_CURSOR.ESPECIALIDAD IN ('Cirugía General', 'Dermatología')     THEN 1200 * REG_CURSOR.DIAS_MOROS
            WHEN REG_CURSOR.ESPECIALIDAD = 'Ortopedia y Traumatología'              THEN 1300 * REG_CURSOR.DIAS_MOROS
            WHEN REG_CURSOR.ESPECIALIDAD IN ('Inmunología', 'Otorrinolaringología') THEN 1700 * REG_CURSOR.DIAS_MOROS
            WHEN REG_CURSOR.ESPECIALIDAD IN ('Fisiatría', 'Medicina Interna')       THEN 1900 * REG_CURSOR.DIAS_MOROS
            WHEN REG_CURSOR.ESPECIALIDAD = 'Medicina General'                       THEN 1100 * REG_CURSOR.DIAS_MOROS
            WHEN REG_CURSOR.ESPECIALIDAD = 'Psiquiatría Adultos'                    THEN 2000 * REG_CURSOR.DIAS_MOROS
            ELSE 2300 * REG_CURSOR.DIAS_MOROS
        END;
        
        SELECT SUM(PORCENTAJE_DESCTO)
        INTO V_PORC_DESC
        FROM PORC_DESCTO_3RA_EDAD
        WHERE REG_CURSOR.EDAD_PAC BETWEEN ANNO_INI AND ANNO_TER;
        
        IF V_PORC_DESC IS NOT NULL THEN
            REG_PAGO_MORO.MONTO_MULTA := ROUND(REG_PAGO_MORO.MONTO_MULTA - REG_PAGO_MORO.MONTO_MULTA * (V_PORC_DESC / 100));
        END IF;
        
        REG_PAGO_MORO.PAC_RUN               := REG_CURSOR.PAC_RUN;
        REG_PAGO_MORO.PAC_DV_RUN            := REG_CURSOR.DV_RUN;
        REG_PAGO_MORO.PAC_NOMBRE            := REG_CURSOR.NOM_PACIENTE;
        REG_PAGO_MORO.ATE_ID                := REG_CURSOR.ATE_ID;
        REG_PAGO_MORO.FECHA_VENC_PAGO       := REG_CURSOR.FECHA_VENC_PAGO;
        REG_PAGO_MORO.FECHA_PAGO            := REG_CURSOR.FECHA_PAGO;
        REG_PAGO_MORO.DIAS_MOROSIDAD        := REG_CURSOR.DIAS_MOROS;
        REG_PAGO_MORO.ESPECIALIDAD_ATENCION := REG_CURSOR.ESPECIALIDAD;
        
        EXIT WHEN CUR_MORA_PAC%NOTFOUND;
        
        INSERT INTO PAGO_MOROSO VALUES REG_PAGO_MORO;
        
    END LOOP;
             
    CLOSE CUR_MORA_PAC;
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ha ocurrido un error');
END;

----------------------------------------------------------------------------------------------------------------------

-- Caso 2)



----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
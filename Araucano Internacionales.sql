CREATE OR REPLACE FORCE VIEW "UDESA"."VW_ARAUCANO_13" ("N_ID_PERSONA", "N_ID_ALU_PROG", "C_IDENTIFICACION", "C_PROGRAMA", "C_ORIENTACION", "N_PROMOCION", "F_BAJA", "F_GRADUACION", "F_INGRESO", "LINEA") AS 
select distinct ap.n_id_persona,
        ap.n_id_alu_prog,        
        ap.c_identificacion,
        ap.c_programa,
        ap.c_orientacion,
        ap.n_promocion,
        ap.f_baja,
        ap.f_graduacion,
        to_char(fun_fecha_ingreso_original(ap.d_registro), 'YYYY') f_ingreso,
        ------------------------------------------------------------------------
        p.d_apellidos || '|' ||                                                                                                 -- 1 apellidos
        p.d_nombres || '|' ||                                                                                                   -- 2 nombres
        devuelve_tipo_doc_araucano(p.c_tipo_documento)||'|' ||                                                                  -- 3 cod_doc       
        p.n_documento||'|' ||                                                                                                   -- 4 nro_docu
        decode(p.m_sexo,'Femenino',2,1) || '|' ||                                                                               -- 5 genero
        to_char(p.f_nacimiento, 'YYYYMMDD') || '|' ||                                                                           -- 6 fecha_nacimiento
        nvl((select pa.n_id_pais_siu from paises pa where p.n_id_pais_nac = pa.n_id_pais ),99999) ||'|'||                       -- 7 pais_nac
'TODO - CREAR LUGAR PARA PAIS PROCEDENCIA (SOLO INCLUIR LOS QUE NOS SEAN ARGENTINA)' ||'|'||                                                     -- 8 pais_procedencia
'TODO - CREAR LUGAR PARA CARGAR FECHA INGRESO PAIS (SOLO TOMAR LOS QUE TENGAN COMPLETO EL DATO)' ||'|'||                        -- 9 fecha_ing_pais
         nvl((case when ap.c_identificacion = 1 then (SELECT pa.n_id_pais_siu
                                                FROM educacion e,
                                                    paises pa
                                                    where e.n_id_pais = pa.n_id_pais
                                                    and e.n_id_persona = p.n_id_persona
                                                    and e.c_nivel = 'Secundario'
                                                    and e.n_id_pais is not null 
                                                    and e.N_ID_EDUCACION = (select max(e2.N_ID_EDUCACION) 
                                                                                from educacion e2 
                                                                                    where p.n_id_persona = e2.n_id_persona
                                                                                    and e2.c_nivel = 'Secundario'
                                                                                    and e2.n_id_pais is not null ))
            when ap.c_identificacion in (2,3) then (SELECT pa.n_id_pais_siu
                                                FROM educacion e,
                                                    paises pa
                                                    where e.n_id_pais = pa.n_id_pais
                                                    and e.n_id_persona = p.n_id_persona
                                                    and e.c_nivel = 'Universitario'
                                                    and e.n_id_pais is not null 
                                                    and e.N_ID_EDUCACION = (select max(e2.N_ID_EDUCACION) 
                                                                                from educacion e2 
                                                                                    where p.n_id_persona = e2.n_id_persona
                                                                                    and e2.c_nivel = 'Universitario'
                                                                                    and e2.n_id_pais is not null ))
            else 99999 end),99999) || '|' ||                                                                                    -- 10 pais_expide_titulo_anterior
        (select e.d_establecimiento 
            FROM educacion e 
                where e.n_id_persona = ap.n_id_persona 
                and n_id_educacion = (select max(n_id_educacion) 
                                        FROM educacion e 
                                            where e.n_id_persona = ap.n_id_persona)) || '|' ||                                  -- 11 institución_origen
        (select e.d_titulo 
                    FROM educacion e 
                        where e.n_id_persona = ap.n_id_persona 
                        and n_id_educacion = (select max(n_id_educacion) 
                                                FROM educacion e 
                                                    where e.n_id_persona = ap.n_id_persona)) || '|' ||                          -- 12 titulo_origen
        devuelve_id_unidad_siu(po.c_identificacion, po.c_programa, po.c_orientacion) ||'|'||                                    -- 13 código_Unidad_Académica 
        case when ap.c_identificacion in (1, 2, 3) and ap.c_condicion_cursada in ('EX', 'EC') then 15766 
            else devuelve_id_unidad_siu(po.c_identificacion, po.c_programa, po.c_orientacion) end || '|' ||                     -- 14 código_propuesta --Codigo enviado por pato Ticket 16662
        nvl((SELECT case when em.c_convenio is not null then 1 else 2 end 
            FROM empresas em
                where em.n_id_empresa in (SELECT e.n_id_establecimiento 
                                        FROM educacion e
                                            where e.n_id_persona = ap.n_id_persona
                                            and e.n_id_educacion = (SELECT max(e2.n_id_educacion)
                                                                    FROM educacion e2
                                                                        where e2.n_id_persona = ap.n_id_persona
                                                                        and e2.n_id_educacion is not null))), 2) || '|' ||          -- 15 convenio
        1 || '|' ||                                                                                                             -- 16 tipo_convenio (optaron por poner todos los convenios como marco)
'TODO - Valores admitidos 1:si - 2:no - Seria siempre 2 menos los casos de cursos cortos crearan una estrucutra' || '|' ||      -- 17 propuesta_formativa 
        99999999 || '|' ||                                                                                                      -- 18 fecha_inicio_propuesta
        99999999 || '|' ||                                                                                                      -- 19 fecha_fin_propuesta
        'SA'                                                                                                                    -- 20 area_propuesta
        linea
    from (select * 
            from alumnos_programas 
                where c_tipo = 'Alumno'
                and n_id_acad_apoyo is null
                and ((c_identificacion in (1,2,3) and c_condicion_cursada in ('EX', 'EC'))
                        or c_identificacion = 5)
                and f_baja is null) ap
    join personas p on ap.n_id_persona = p.n_id_persona  
    join programas po on po.c_identificacion = ap.c_identificacion 
                  and po.c_programa = ap.c_programa 
                  and po.c_orientacion = ap.c_orientacion
    --join deptos_academicos da on da.c_depto = po.c_depto
    --inner join plan_estudio pe on pe.c_identificacion = ap.c_identificacion and pe.c_programa = ap.c_programa and pe.c_orientacion = ap.c_orientacion and pe.c_plan = ap.c_plan
        --and po.m_oficial = 'Si'
        --and (pe.n_id_titulo_siu is not null or po.n_id_titulo_siu is not null)
        
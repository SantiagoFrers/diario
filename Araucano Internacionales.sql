select  ap.n_id_persona,
        ap.n_id_alu_prog,        
        ap.c_identificacion,
        ap.c_programa,
        ap.c_orientacion,
        ap.n_promocion,
        ap.f_baja,
        ap.f_graduacion,
        to_char(fun_fecha_ingreso_original(ap.d_registro), 'YYYY') f_ingreso,
        ------------------------------------------------------------------------
        p.d_apellidos || '|' ||                                                                               -- 1 apellidos
        p.d_nombres || '|' ||                                                                                 -- 2 nombres
        devuelve_tipo_doc_araucano(p.c_tipo_documento)||'|' ||                                              -- 3 cod_doc       
        p.n_documento||'|' ||                                                                               -- 4 nro_docu
        decode(p.m_sexo,'Femenino',2,1) || '|' ||                                                           -- 5 genero
        to_char(p.f_nacimiento, 'YYYYMMDD') || '|' ||                                                       -- 6 fecha_nacimiento
        nvl((select pa.n_id_pais_siu from paises pa where p.n_id_pais_nac = pa.n_id_pais ),99999) ||'|'||   -- 7 pais_nac
        'TODO - PAIS PROCEDENCIA' ||'|'||                                                                   -- 8 pais_procedencia
        'TODO - FECHA INGRESO PAIS' ||'|'||                                                                 -- 9 fecha_ing_pais
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
            else 99999 end),99999) || '|' ||                                                                 -- 10 pais_expide_titulo_anterior
        'TODO - Institución de Origen' || '|' ||                                                             -- 11 institución_origen
        'TODO - Titulo de Origen' || '|' ||                                                                  -- 12 titulo_origen
        devuelve_id_unidad_siu(po.c_identificacion, po.c_programa, po.c_orientacion) ||'|'||                 -- 13 código_Unidad_Académica 
        15766 || '|' ||                                                                                      -- 14 código_propuesta --Codigo enviado por pato Ticket 16662
        'TODO - Con convenio?' || '|' ||                                                                     -- 15 convenio
        'TODO - Tipo convenio' || '|' ||                                                                     -- 16 tipo_convenio
        'TODO - Propuesta formativa' || '|' ||                                                               -- 17 propuesta_formativa
        'TODO - Fecha inicio propuesta' || '|' ||                                                             -- 18 fecha_inicio_propuesta
        'TODO - Fecha finalizacion de la propuesta' || '|' ||                                                -- 19 fecha_fin_propuesta
        'TODO - Area propuesta'                                                                              -- 20 area_propuesta
        linea
    from alumnos_programas ap
    join personas p on ap.n_id_persona = p.n_id_persona  
    join programas po on po.c_identificacion = ap.c_identificacion 
                  and po.c_programa = ap.c_programa 
                  and po.c_orientacion = ap.c_orientacion
    join deptos_academicos da on da.c_depto = po.c_depto
    inner join plan_estudio pe on pe.c_identificacion = ap.c_identificacion and pe.c_programa = ap.c_programa and pe.c_orientacion = ap.c_orientacion and pe.c_plan = ap.c_plan
        and ap.c_tipo = 'Alumno'
        and ap.n_id_acad_apoyo is null
        and ap.c_identificacion in (1,2,3)
        and ap.c_condicion_cursada in ('EX', 'EC')
        and po.m_oficial = 'Si'
        and ap.f_baja is null 
        and (pe.n_id_titulo_siu is not null or po.n_id_titulo_siu is not null)
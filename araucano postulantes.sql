select distinct ap.n_id_persona,
        ap.n_id_alu_prog,
        ap.d_apellidos,
        ap.d_nombres,
        ap.c_identificacion,
        ap.c_programa,
        ap.c_orientacion,
        ap.n_promocion,
        ap.f_baja,
        ap.f_graduacion,
        to_char(fun_fecha_ingreso_original(ap.d_registro), 'YYYY') f_ingreso,           
        ------------------------------------------------------------------------
        devuelve_tipo_doc_araucano(p.c_tipo_documento)||'|' ||                                  -- 1 cod_doc       
        p.n_documento||'|' ||                                                                   -- 2 nro_docu
        nvl(p.n_cuit, '') ||'|' ||                                                              -- 3 cuit
        decode(p.m_sexo,'Femenino',2,1) || '|' ||                                               -- 4 genero
        to_char(p.f_nacimiento, 'YYYYMMDD') || '|' ||                                           -- 5 fecha_nacimiento
        to_char(sa.created_at, 'YYYYMMDD') || '|' ||                                            -- 6 fecha_alta_sistema
        devuelve_id_unidad_siu(po.c_identificacion, po.c_programa, po.c_orientacion) ||'|'||    -- 7 Código de Unidad Académica 
        nvl(pe.n_id_titulo_siu, po.n_id_titulo_siu) ||'|'||                                     -- 8 cod_Tit_siu
        nvl((select 1 from applications app where app.APPLICATION_ID = sa.APPLICATION_ID 
        and application_type_id = 9 and state = 'P'), 2) ||'|'||                                -- 9 requisitos_administrativos      
        case when sa.state in ('A', 'M') then 1 else 2 end ||'|'||                              -- 10 requisitos_academicos
        case when (select 1 from applications app where app.APPLICATION_ID = sa.APPLICATION_ID 
        and application_type_id = 9 and state = 'P') = 1 and sa.state in ('A', 'M') then 1 
        else 2 end  ||'|'||                                                                     -- 11 condiciones_ingreso
        to_char(ap.f_ingreso, 'YYYYMMDD')                                                       -- 12 fecha_finalizacion_ingreso
        linea
 from alumnos_programas ap
 join personas p on ap.n_id_persona = p.n_id_persona  
 join programas po on po.c_identificacion = ap.c_identificacion 
                   and po.c_programa = ap.c_programa 
                   and po.c_orientacion = ap.c_orientacion
 join sigedu.applicants sa on ap.n_id_solicitud = sa.APPLICATION_ID
 join deptos_academicos da on da.c_depto = po.c_depto
 inner join plan_estudio pe on pe.c_identificacion = ap.c_identificacion and pe.c_programa = ap.c_programa and pe.c_orientacion = ap.c_orientacion and pe.c_plan = ap.c_plan
 where exists ( select * 
                        from (SELECT ap2.n_id_persona, max(ap2.n_id_alu_prog) n_id_alu_prog
                                FROM alumnos_programas ap2
                                    where 1 = 1
                                    and n_id_calen_cursada in (SELECT n_id_calen_cursada
                                                                    FROM vw_calendarios_admision_new
                                                                        where f_inicio_cursada BETWEEN '01/03/' || :anio and '31/12/' || :anio 
                                                                        and c_identificacion = 1) -- Calendarios de cursado Marzo / Agosto 2020 tabla calendarios_cursadas
                                    and ap2.c_identificacion = 1
                                    and ap2.c_tipo = 'Postulante'
                                    group by ap2.n_id_persona) x
                            where ap.n_id_alu_prog = x.n_id_alu_prog
                    )
    and po.m_oficial = 'Si'
    and n_id_calen_cursada in (5924,5386)
    and ap.c_identificacion = 1
    and ap.c_tipo = 'Postulante'   
    and (pe.n_id_titulo_siu is not null or po.n_id_titulo_siu is not null)
;

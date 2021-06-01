--Archivo araucano 0
select  ap.n_id_persona,
        ap.n_id_alu_prog,
        ap.c_identificacion,
        ap.c_programa,
        ap.c_orientacion,
        ap.n_promocion,
        ap.f_baja,
        ap.f_graduacion,        
        to_char(fun_fecha_ingreso_original(ap.d_registro),'YYYY')f_ingreso,
        ------------------------------------------------------------------------
        upper(p.d_apellidos) ||'|' ||                                                                      -- 1 apellido
        upper(p.d_nombres) ||'|' ||                                                                        -- 2 nombre
        devuelve_tipo_doc_araucano(p.c_tipo_documento) ||'|' ||                                            -- 3 cod_doc
        p.n_documento ||'|' ||                                                                             -- 4 nro_doc

-- 31052021 Franco: Ticket 015583 Upgrade en calidad de informacion  
        --nvl(p.n_cuit,'99999999999')||'|' ||                                                              -- 5 cuit/cuil
        case when p.n_cuit is not null then p.n_cuit
             when p.N_ID_PAIS_NAC != 2 and p.n_cuit is null then 88888888888
             else 99999999999 
        end ||'|' ||                                                                                       -- 5 cuit/cuil
        
        decode(p.m_sexo,'Femenino',2,1) ||'|' ||                                                           -- 6 genero
        to_char(p.f_nacimiento, 'YYYYMMDD') ||'|' ||                                                       -- 7 fecha_nac,       
        devuelve_cue(p.n_id_persona)||'|' ||                                                               -- 8 cue

-- 31052021 Franco: Ticket 015583 
        --'NT' ||'|' ||                                                                                    -- 9 cod_horas_trabajo,
        'NDI' ||'|' ||                                                                                     -- 9 cod_horas_trabajo,        

-- 31052021 Franco: Ticket 015583 
        --9 ||'|' ||                                                                                       -- 10 cod_nivel_ins_padre
        nvl((select case when c_titulo_universitario is not null then 7
                            else 10 end
                from familia f
                    where f.n_id_persona = p.n_id_persona
                    and c_parentesco = 'Padre'), 10) ||'|' ||                                              -- 10 cod_nivel_ins_padre

-- 31052021 Franco: Ticket 015583 
        --9 ||'|' ||                                                                                       -- 11 cod_nivel_ins_madre,
        nvl((select case when c_titulo_universitario is not null then 7
                            else 10 end
                from familia f
                    where f.n_id_persona = p.n_id_persona
                    and c_parentesco = 'Madre'), 10) ||'|' ||                                              -- 11 cod_nivel_ins_madre,

-- 31052021 Franco: Ticket 015583 
        --(select nvl(pa.n_id_pais_siu,99999) from paises pa where p.n_id_pais_nac = pa.n_id_pais ) ||'|'||-- 12 pais_nac
        nvl((select pa.n_id_pais_siu from paises pa where p.n_id_pais_nac = pa.n_id_pais ),99999) ||'|'||  -- 12 pais_nac

-- 31052021 Franco: Ticket 015583 
--        99999 ||'|' ||                                                                                   -- 13 pais_domicilio_procedencia
        nvl((SELECT n_id_pais_siu
            FROM direcciones d,
                paises p
                    where d.n_id_pais = p.n_id_pais
                    and p.n_id_persona = d.n_id_persona
                    and c_domicilio = 'Particular 1'), 99999) ||'|' ||                                     -- 13 pais_domicilio_procedencia

-- 31052021 Franco: Ticket 015583 
        --99999999 ||'|' ||                                                                                -- 14 fecha ingreso al pais
        nvl(p.F_INGRESO_PAIS, 99999999) ||'|' ||                                                           -- 14 fecha ingreso al pais
        
-- 31052021 Franco: Ticket 015583 
        --99999 ||'|' ||                                                                                   -- 15 pais_expide_titulo_anterior
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
            else 99999 end),99999) ||'|' ||                                                                -- 15 pais_expide_titulo_anterior
                           
-- 31052021 Franco: Ticket 015583 
        --'' ||'|' ||                                                                                      -- 16 localidad_procedencia
        nvl((SELECT n_id_localidad_siu
            FROM direcciones d,
                localidades l
                    where d.n_id_localidad = l.n_id_localidad
                    and p.n_id_persona = d.n_id_persona
                    and c_domicilio = 'Particular 1'), '') ||'|' ||                                        -- 16 localidad_procedencia
        
        nvl(p.m_genero,0) ||'|' ||                                                                         -- 17 Identidad de Género y Diversidad
        nvl(p.d_descrip_genero,'')                                                                         -- 18 Identidad de Género y Diversidad
        linea
   from alumnos_programas ap
   join personas p on ap.n_id_persona = p.n_id_persona
   join programas po on ap.c_identificacion = po.c_identificacion 
                     and ap.c_programa = po.c_programa 
                     and ap.c_orientacion = po.c_orientacion
    and ap.c_tipo = 'Alumno'
    and ap.n_id_acad_apoyo is null
    and po.m_oficial = 'Si'
    and ap.c_condicion_cursada != 'EX'
    and ap.c_identificacion in (1,2,3)
    and ap.f_baja is null -- ALE 20201009 /*Incluye reinscriptos,nuevos inscriptos y egresados */
;
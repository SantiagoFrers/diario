select --p.d_descred cod_programa,
       p.d_descrip desc_programa,
       (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
          from UDESA.Alumnos_Programas ap2
         where ap2.n_id_persona = ap.n_id_persona 
           and ap2.n_id_alu_prog != ap.n_id_alu_prog
           and ap2.c_tipo         = 'Alumno'
           and ap2.n_id_acad_apoyo is null
           and ap2.f_baja is null
           and ap2.c_identificacion = 1
           and ap2.f_graduacion is null        
       )programa_2,
       ap.n_promocion promocion,
       --ap.n_id_alu_prog id_alumno, 
       --ap.n_id_alu_prog_sig id_siguiente, 
       ap.d_registro legajo, 
       ap.d_apellidos apellidos,
       ap.d_nombres nombres,
       ap.f_ingreso fecha_ingreso,
       devuelve_f_ingreso_original(ap.n_id_alu_prog) fecha_ingreso_original,
       ap.f_baja fecha_baja,
       devuelve_cg_ref_meaning('TIPOS DE BAJAS', ap.c_baja) motivo_baja,
       ap.f_graduacion fecha_graduacion,
       (select  LISTAGG(ba.D_BECAS, '; ') WITHIN GROUP (ORDER BY ba.f_desde)
            from VW_BECAS_CONCATENADAS ba
        where 1=1
        and ba.n_id_alu_prog = ap.n_id_alu_prog
        and SYSDATE between ba.f_desde and ba.f_hasta
       ) becas,
       (select  LISTAGG(ba.f_desde, '; ') WITHIN GROUP (ORDER BY ba.f_desde)
          from VW_BECAS_CONCATENADAS ba
        where 1=1
        and ba.n_id_alu_prog = ap.n_id_alu_prog
        and SYSDATE between ba.f_desde and ba.f_hasta
       ) desde,
        (select
                 LISTAGG(ba.f_hasta, '; ') WITHIN GROUP (ORDER BY ba.f_hasta)
            from VW_BECAS_CONCATENADAS ba
        where 1=1
        and ba.n_id_alu_prog = ap.n_id_alu_prog
        and SYSDATE between ba.f_desde and ba.f_hasta
       ) hasta,
       pe.m_sexo sexo, 
       pe.c_tipo_documento tipo_doc,
       pe.n_documento numero_doc,
       edad(pe.n_id_persona) edad,
       fun_tel_mail(pe.n_id_persona,'T') tel,
       --di.d_direccion || ' ' || di.n_direccion direccion,
       --di.d_piso piso,
       --di.d_depto departamento,
       --di.c_postal cp,
       devuelve_desc_localidad(di.n_id_localidad) localidad,
       devuelve_desc_provincia(di.n_id_provincia) provincia,
       devuelve_desc_pais(di.n_id_pais) pais,
       devuelve_desc_localidad(w.n_id_localidad) localidad_origen,
       devuelve_desc_provincia(w.n_id_provincia) provincia_origen,
       devuelve_desc_pais(w.n_id_pais) pais_origen,
       (select co.c_email
          from correos co
          where pe.n_id_persona = co.n_id_persona 
          and co.c_correo = 'E-Mail Interno'
          ) mail_udesa,
        (select listagg ( co2.c_email,';' )
                within group ( order by co2.c_email )
          from correos co2
          where pe.n_id_persona = co2.n_id_persona 
           and co2.c_correo != 'E-Mail Interno'
          group by pe.n_id_persona
        ) mail_alternativo,
        (
        select f.c_email
          from familia f
         where f.c_parentesco = 'Padre'
           and f.n_id_persona = pe.n_id_persona
       ) mail_padre,
       (
        select f.c_email
          from familia f
         where f.c_parentesco = 'Madre'
           and f.n_id_persona = pe.n_id_persona
       ) mail_madre,
       --round(ed.n_promedio_udesa,2) promedio_colegio,
       --round((to_number(udesa.devuelve_nota_requisito_post(ap.n_id_alu_prog, 'E1')) + to_number(udesa.devuelve_nota_requisito_post(ap.n_id_alu_prog, 'E2'))/2),2) prom_ingreso,
        --pac_bloqueos_udesa.prom_gral_carrera(ap.n_id_alu_prog,'TODAS_MATERIAS') promedio_carrera,
        --pac_bloqueos_udesa.prom_gral_carrera(ap.n_id_alu_prog,'PLAN_ESTUDIO') promedio_plan,
        --initcap(nvl(em.d_empresa, ed.d_establecimiento)) colegio,
       --decode(ed.n_id_establecimiento, null, '- No listado -', emd.d_direccion || emd.n_domicilio) direccion_colegio,
       --devuelve_desc_pais(nvl(emd.n_id_pais, ed.n_id_pais) ) pais_colegio,
       --devuelve_desc_provincia(nvl(emd.n_id_provincia, ed.n_id_provincia) )  provincia_colegio,
       --devuelve_desc_localidad(nvl(emd.n_id_localidad, ed.n_id_localidad) ) localidad_colegio,
       --nvl(emd.c_postal, ' - No Listado - ') cod_postal_colegio,
       /*(select listagg ( devuelve_cg_ref_meaning('CONDICIONES DE ADMISION',pc.c_condicion),' / ' ) within group ( order by pc.c_condicion)
          from postul_condiciones pc,
               postulantes po
          where pc.n_id_postulante = po.n_id_postulante
            and po.n_id_alu_prog = devuelve_aluprog_postulante(ap.n_id_alu_prog)
            and po.c_resultado_admis = 'ADMICOND'
           and po.n_id_postulante_sig is null
       ) condiciones,*/
       pac_facturacion.devuelve_cant_obligaciones(ap.n_id_alu_prog) + ap.n_cont_cuota_inicial contador_cuotas,
       case when to_number(to_char(ap.f_ingreso,'yyyymm')) <= to_number(to_char(sysdate,'yyyymm'))
         then to_number(decode(ap.f_baja, null, decode(ap.c_vinculo, 'C', null, devuelve_cuotas_faltantes(ap.n_id_alu_prog) ) , null ) )
       else
         0
       end cuotas_faltantes
from   programas pr
       join alumnos_programas ap on  ap.c_orientacion = decode(pr.c_orientacion   ,0, ap.c_orientacion,    pr.c_orientacion)
                                 and ap.c_programa = decode(pr.c_programa      ,0, ap.c_programa,       pr.c_programa)
                                 and ap.c_identificacion = decode(pr.c_identificacion,0, ap.c_identificacion, pr.c_identificacion)
                                 and ap.c_tipo = 'Alumno'
                                 and ap.n_id_acad_apoyo is null
       join programas p on  p.c_orientacion = ap.c_orientacion
                             and p.c_programa = ap.c_programa
                             and p.c_identificacion = ap.c_identificacion
       join personas pe on pe.n_id_persona = ap.n_id_persona
       left join web_sol_principal w on w.n_id_solicitud = nvl(ap.n_id_solicitud, (SELECT max(ap3.n_id_solicitud)
                                                                                        FROM alumnos_programas ap3
                                                                                    where ap3.N_ID_PERSONA = ap.N_ID_PERSONA
                                                                                    and ap3.c_identificacion = ap.c_identificacion
                                                                                    )
                                                               )
       left join direcciones di on di.n_id_persona = pe.n_id_persona 
                             and   di.c_domicilio = pe.m_envio 
       left join educacion ed on ed.n_id_persona = pe.n_id_persona
                             and ed.n_id_educacion = devuelve_id_educacion(pe.n_id_persona , 'Secundario')
       left join empresas em on em.n_id_empresa = ed.n_id_establecimiento
       left join empresas_domicilios emd on emd.n_id_empresa = em.n_id_empresa

where  1=1 
and seguridad_ipo_web(null, ap.c_identificacion, ap.c_programa, ap.c_orientacion, :APP_USER) = 'TRUE'
and PR.D_DESCRED         = 'GRADO'
and verificar_estado_alumno_rango(ap.n_id_alu_prog,'ACTIVO', SYSDATE, SYSDATE) = 'TRUE'
and exists (select 1 
                from alumnos_programas ap2
                     join becas_alumnos_cab bac on bac.n_id_alu_prog = ap2.n_id_alu_prog
                                                and SYSDATE between bac.f_desde and bac.f_hasta
                     join becas_alumnos ba on ba.n_id_solicitud_beca = bac.n_id_solicitud_beca
                                           and ba.c_tipo_forma = 'OTO'
                                           --and ba.n_id_beca_fin = nvl(:p1_beca,ba.n_id_beca_fin)
                where ap2.n_id_alu_prog = ap.n_id_alu_prog
               ) 
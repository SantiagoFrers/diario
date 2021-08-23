with alumnos as (select ap.n_id_alu_prog,
                        ap.n_promocion promocion,
                        p.d_descred cod_orien,
                        p.d_descred orientacion,
                        ap.f_ingreso,
                        ap.d_apellidos||', '||ap.d_nombres alumno,
                        ap.d_registro legajo,
                        pac_bloqueos_udesa.prom_gral_carrera(ap.n_id_alu_prog,'TODAS_MATERIAS') promedio_general,
                        pac_bloqueos_udesa.prom_gral_acumulado(ap.n_id_alu_prog) prom_acumulado,
                        pac_bloqueos_udesa.prom_carrera_periodo(ap.n_id_alu_prog, (select vw.f_inicio from vw_calendarios vw where vw.n_id_cal_periodo = :P1_PERIODO_HASTA), (select vw.f_fin from vw_calendarios vw where vw.n_id_cal_periodo = :P1_PERIODO_HASTA), 'TODAS_MATERIAS') prom_periodo,
                        decode(ap.c_programa, 11, null, devuelve_dato_arancel(ap.n_id_alu_prog,'FALTANTES')) cuotas_faltantes,
                        udesa.cursa_dos_carreras(ap.d_registro,ap.c_identificacion) multiple_cursado
                    from alumnos_programas ap,
                        programas p
                             where ap.c_tipo = 'Alumno'
                               and ap.n_id_acad_apoyo is null
                               and ap.f_graduacion is null
                               and (ap.n_id_alu_prog_sig is null or ap.c_baja in ('CC','CP'))
                               and (ap.f_baja is null or ap.f_baja >= (select vw.f_fin from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA))
                               and ap.c_identificacion = 1
                               --and ap.c_programa       = decode(:p_prog,  0, ap.c_programa,       :p_prog)
                               --and ap.c_orientacion    = decode(:p_orien, 0, ap.c_orientacion,    :p_orien)
                               and ap.n_promocion between nvl(:p1_promo_desde,0) and nvl(:p1_promo_hasta,99999)
                               and ap.c_identificacion = p.c_identificacion
                               and ap.c_programa = p.c_programa
                               and ap.c_orientacion = p.c_orientacion
                               and ap.c_vinculo  not in ('FF','N')
                               and decode(ap.c_programa, 11, 1, devuelve_dato_arancel(ap.n_id_alu_prog,'FALTANTES')) > 0
                               and ((:p1_becarios = 'Si' 
                                     and exists (select 1
                                                   from becas_alumnos_cab bac,
                                                        becas_alumnos ba,
                                                        becas b
                                                  where ap.n_id_alu_prog = bac.n_id_alu_prog
                                                    and b.n_id_beca_fin = ba.n_id_beca_fin
                                                    and fun_between_fechas(bac.f_desde, bac.f_hasta, (select vw.f_inicio from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA), (select vw.f_fin from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA)) = 'S'
                                                    and bac.n_id_solicitud_beca = ba.n_id_solicitud_beca
                                                    and ba.c_tipo_forma = 'OTO'
                                                    and b.m_merito = 'Si'
                                                )
                                    ) 
                                    or :p1_becarios = 'No'
                                   )
                            order by ap.n_promocion, upper(ap.d_apellidos||', '||ap.d_nombres) ),

aplazos as (select ap.n_id_alu_prog aluprog_q2, m.d_descrip materia, nvl(al.d_nota_letra, al.n_nota_numero) nota
                from alumnos_programas ap,
                   alumnos_programas ap2,      
                   alumnos_libretas  al,
                   materias          m
                     where ap2.d_registro        = ap.d_registro
                       and ap2.n_id_alu_prog     = al.n_id_alu_prog   
                       and m.n_id_materia       = al.n_id_materia
                       and al.m_aprueba_mat      = 'No'
                       and al.c_clase_evalua     in ('Final','RECUFIN','Tesis')
                       and nvl(al.d_nota_letra,'-') not in ('U', 'R')
                       and fun_between_fechas(al.f_rinde, al.f_rinde, (select vw.f_inicio from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA), (select vw.f_fin from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA)) = 'S'
                       and al.f_anulacion  is null),

bajas as (select ca.d_descred, ap.n_id_alu_prog n_id_alu_prog_q4
            from alumnos_programas ap,
                vw_cursos_alumnos ca
                    where ca.n_id_alu_prog = ap.n_id_alu_prog
                    and ca.f_baja_alucur is not null -- Que tengan baja al curso
                    and ca.C_BAJA_ALUCUR not in ('CC', 'L') -- Exluimos bajas por Cambio de carrera o Licencias
                    and (ca.C_BAJA_ALUCUR in ('A', 'O', 'VO-PENALIZACION') 
                        --las bajas VO las filtramos entre 10/03 y 12/07 y entre 10/08 y 15/12
                        or (ca.C_BAJA_ALUCUR = 'VO' and to_number(to_char(ca.f_baja_alucur, 'mmdd')) between 0310 and 0712
                            or to_number(to_char(ca.f_baja_alucur, 'mmdd')) between 0810 and 1215))
                    and ap.c_identificacion = 1 -- Solo Grado
                    and ca.c_tipo_clase = 'Teórica'
                    --and ap.f_baja is null -- Que no esten de baja de Universidad
                    and exists (select  1 -- Que tenga alguna beca/credito
                                  from becas_alumnos_cab bac,
                                       becas_alumnos ba,
                                       becas b
                                 where fun_between_fechas(bac.f_desde, bac.f_hasta, (select vw.f_inicio from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA), (select vw.f_fin from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA)) = 'S'
                                   and bac.n_id_solicitud_beca = ba.n_id_solicitud_beca
                                   and ba.c_tipo_forma = 'OTO'
                                   and b.m_merito = 'Si'
                                   and ba.n_id_beca_fin = b.n_id_beca_fin
                                   and ap.n_id_alu_prog = bac.n_id_alu_prog)),
                                           
alumnos_becas as (select bac.n_id_alu_prog aluprog_q3, b.d_descrip desc_beca, ba.n_porcentaje porc_beca
              from becas_alumnos_cab bac,
                   becas_alumnos ba,
                   
                   becas b
                     where fun_between_fechas(bac.f_desde, bac.f_hasta, (select vw.f_inicio from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA), (select vw.f_fin from vw_calendarios vw      where vw.n_id_cal_periodo = :P1_PERIODO_HASTA)) = 'S'
                       and bac.n_id_solicitud_beca = ba.n_id_solicitud_beca
                       and ba.c_tipo_forma = 'OTO'
                       and ba.n_id_beca_fin = b.n_id_beca_fin )

SELECT distinct a. promocion "Promocion", a.alumno "Alumno", a.legajo "Legajo", a.orientacion "Orientacion", a.f_ingreso "Fecha ingreso", decode(a.multiple_cursado, 'True', 'Si', 'False', 'No') "Doble carrera", a.promedio_general "Prom. General", a.prom_periodo as "Prom. Perido", a.prom_acumulado "Prom. Acumulado",
        (select pac_bloqueos_udesa.cant_aplazos_alumno (a.n_id_alu_prog , 'N') from dual) "Aplazos Totales",
        a.cuotas_faltantes "Cuotas Faltantes",
        (select nvl(Listagg(ap.materia || ' - ' || ap.nota, ' / ') Within Group (Order By 1), '---') from aplazos ap where a.n_id_alu_prog = ap.aluprog_q2) "Aplazos del Periodo",
        (select nvl(Listagg(b.d_descred, ' / ') Within Group (Order By 1), '---') from bajas b where a.n_id_alu_prog = b.n_id_alu_prog_q4) "Bajas Materias",
        (select nvl(Listagg(ab.desc_beca || ' - ' || ab.porc_beca, ' / ') Within Group (Order By 1), '---') from alumnos_becas ab where a.n_id_alu_prog = ab.aluprog_q3) "Asistencia financiera"
    FROM alumnos a
        order by 2, 1
        ;

with datos as (SELECT distinct ap.n_id_persona, ac.d_registro registro, ap.n_promocion, ap.d_apellidos apellido, ap.d_nombres nombre, (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2 
                                                                                                                                            from    UDESA.Alumnos_Programas ap2
                                                                                                                                                        where ap2.n_id_persona = AP.n_id_persona
                                                                                                                                                        and ap2.c_tipo = 'Alumno'
                                                                                                                                                        and ap2.n_id_acad_apoyo is null
                                                                                                                                                        and ap2.f_baja is null
                                                                                                                                                        and ap2.c_identificacion = 1
                                                                                                                                                        and ap2.f_graduacion is null ) carrera,
m.d_descred materia, ac.n_id_cur_tipoclase, NVL(decode(ap.n_id_modalidad,922, 'CABA', 923, 'CAMPUS', 924, 'CAMPUS - DH' , 925, 'CABA - DH', 1142, 'CAMPUS - CABA'),'SIN MODALIDAD') modalidad, p.n_id_persona docente, p.nombre "NOMBRE DOCENTE", 
decode(ch.c_dia_semanal, 'Lunes', '1 - Lunes', 'Martes', '2 - Martes', 'Miércoles', '3 - Miércoles', 'Jueves', '4 - Jueves', 'Viernes', '5 - Viernes', 'Sin dia' )dia, 
--ch.n_hora_desde "HORA DESDE", 
(SELECT min(ch2.n_hora_desde) FROM cursos_horarios ch2 where  ch2.n_id_cur_tipoclase = ch.n_id_cur_tipoclase) "HORA DESDE",
m.d_descred || '-' || p.n_id_persona || '-' || p.nombre || '-' || ch.c_dia_semanal || '-' || (SELECT min(ch2.n_hora_desde) FROM cursos_horarios ch2 where  ch2.n_id_cur_tipoclase = ch.n_id_cur_tipoclase) "UNIFICADOR", mgd.c_frecuencia
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        cursos c,
        cursos_tipoclase ct,
        cursos_horarios ch,
        (SELECT distinct(devuelve_apenom_per_fic(cp.person_id)) nombre, person_id n_id_persona 
            FROM sigedu.classification_people cp
        UNION ALL
        SELECT D_DOCENTE NOMBRE, n_id_ficticio n_id_persona
            FROM docentes_ficticios) p,
        (SELECT mgd2.n_id_cur_tipoclase, mgd2.c_frecuencia, max(mgd2.n_id_persona) n_id_persona
            FROM  materias_grupos_det mgd2
                where 1=1
                and n_id_cal_periodo =:periodo
                and ((:final = 'S' and mgd2.c_tipo_final = 'Presencial') or (:final = 'N'))
                and ((:parcial = 'S' and mgd2.c_tipo_parcial = 'Presencial') or (:parcial = 'N'))
                --TODO AGREGAR PARCIALES PARA FILTRAR POR FINAL O PARCIAL and mgd2.c_tipo_final = 'Presencial'
                group by mgd2.n_id_cur_tipoclase, mgd2.c_frecuencia) mgd
        where 1= 1
        and ac.n_id_alu_prog = ap.n_id_alu_prog
        and ac.n_id_materia = m.n_id_materia
        and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
        and ct.n_id_cur_tipoclase = ch.n_id_cur_tipoclase
        and ct.n_id_cur_tipoclase = mgd.n_id_cur_tipoclase
        and p.n_id_persona = mgd.n_id_persona
        and c.n_id_curso = ct.n_id_curso
        and c.n_id_cal_periodo =:periodo
        and ac.f_baja is null
        and ct.c_tipo_clase = 'Teórica'
        and ap.c_identificacion = 1
        --and ct.n_id_cur_tipoclase = 78711
        --and p.n_id_persona = 121102
        --and ac.n_id_alu_prog in (79917, 99660)
        --and ac.d_registro in ('33081')
        --AND D_DESCRED = 'D300'       
        ),
        
parciales_juntos as (select distinct mgd.n_id_cur_tipoclase
    from materias_grupos_det mgd,
        (select m.n_id_materia, m.d_descred module_code, d.n_id_persona accademystaff, d.n_sede, d.n_grupo grupo, count(*)
            from materias_grupos_cab c,
                materias_grupos_det d,
                materias m
                    where c.n_id_cal_periodo= :periodo
                    and c.n_id_materia=m.n_id_materia
                    and d.n_id_materia= m.n_id_materia
                    and c.n_id_mat_grupo_cab=d.n_id_mat_grupo_cab
                    and d.c_tipo_dictado='PRESENCIAL'
                    and d.c_tipo_clase = 'TE'
                         group by m.n_id_materia, m.d_descred, d.n_id_persona, d.n_sede, d.n_grupo
                         HAVING COUNT(*) > 1
                         order by 1, 2) x
            where x.n_id_materia = mgd.n_id_materia
            and x.accademystaff = mgd.n_id_persona
            and x.n_sede = mgd.n_sede
            and x.grupo = mgd.n_grupo
            and mgd.n_id_cal_periodo= :periodo
            and mgd.c_tipo_dictado='PRESENCIAL'
            and mgd.c_tipo_clase = 'TE')

select d.*, 'Semana 1' as semana, case when c_frecuencia = '1x2' or c_frecuencia = '1x1' then 'Dia fijo' else '-' end "Dia fijo", case when p.n_id_cur_tipoclase is not null then 'Grupos juntos' else '-' end "Grupos juntos"
    from datos d
        left join parciales_juntos p on d.n_id_cur_tipoclase = p.n_id_cur_tipoclase
UNION ALL
select d.*, 'Semana 2' as semana, case when c_frecuencia = '1x2' or c_frecuencia = '1x1' then 'Dia fijo' else '-' end "Dia fijo", case when p.n_id_cur_tipoclase is not null then 'Grupos juntos' else '-' end "Grupos juntos"
    from datos d
        left join parciales_juntos p on d.n_id_cur_tipoclase = p.n_id_cur_tipoclase
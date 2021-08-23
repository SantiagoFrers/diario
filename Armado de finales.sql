SELECT distinct ac.n_id_alu_prog, ac.d_registro registro, ap.n_promocion, ap.d_apellidos apellido, ap.d_nombres nombre, (Select p.d_descrip from udesa.programas p where p.c_identificacion = ap.c_identificacion and p.c_programa = ap.c_programa and p.c_orientacion = ap.c_orientacion) carrera, m.d_descred materia, ac.n_id_cur_tipoclase, NVL(decode(ap.n_id_modalidad,922, 'CABA', 923, 'CAMPUS', 924, 'CAMPUS - DH' , 925, 'CABA - DH', 1142, 'CAMPUS - CABA'),'SIN MODALIDAD') modalidad, p.n_id_persona , p.d_apellidos || ',' || p.d_nombres "DOCENTE", ch.c_dia_semanal dia, ch.n_hora_desde "HORA DESDE",
m.d_descred || '-' || p.n_id_persona || '-' || ch.c_dia_semanal || '-' || ch.n_hora_desde "UNIFICADOR"
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        cursos c,
        cursos_tipoclase ct,
        cursos_horarios ch,
        personas p,
        (SELECT mgd.n_id_cur_tipoclase, mgd.c_tipo_final, max(n_id_persona) n_id_persona
            FROM  materias_grupos_det mgd
                where 1=1
                and n_id_cal_periodo =:periodo
                group by mgd.n_id_cur_tipoclase, mgd.c_tipo_final) mgd
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
        and mgd.c_tipo_final = 'Presencial'
        --and ct.n_id_cur_tipoclase = 78711
        --and p.n_id_persona = 121102
        --and ac.n_id_alu_prog in (79917, 99660)
        --and ac.d_registro in ('33081')
        --AND D_DESCRED = 'D300'
        order by 1 desc, 2
       ; --8342

SELECT mgd.n_id_cur_tipoclase, mgd.c_tipo_final, max(n_id_persona) n_id_persona
    FROM  materias_grupos_det mgd
        where 1=1
        and n_id_cal_periodo =:periodo
        and mgd.n_id_cur_tipoclase = 78711
        group by mgd.n_id_cur_tipoclase, mgd.c_tipo_final
        ;

SELECT * 
    FROM cursos_tipoclase
        where n_id_cur_tipoclase in (78934, 78916, 78900);
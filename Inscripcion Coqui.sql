--INSCRIPCION CONFIRMADA
SELECT to_char(ac.f_alta, 'dd/mm/yyyy') "Fecha alta", to_char(ac.f_alta,'hh24:mi') "Hora alta", ac.c_usuarioalt "Usuario alta", to_char(ac.f_actualizac, 'dd/mm/yyyy')"Fecha actualizacion", to_char(ac.f_actualizac,'hh24:mi') "Hora actualizacion", ac.c_usuarioact "Usuario actualizacion", ac.f_baja "Fecha baja",ap.n_id_persona, ac.n_id_alu_prog, ac.d_registro, ap.n_promocion, ap.d_apellidos, ap.d_nombres, 
(Select p.d_descrip from udesa.programas p where p.c_identificacion = ap.c_identificacion and p.c_programa = ap.c_programa and p.c_orientacion = ap.c_orientacion) carrera,
(select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
                                                            from    UDESA.Alumnos_Programas ap2
                                                                        where ap2.n_id_persona = AP.n_id_persona
                                                                        and ap2.c_tipo = 'Alumno'
                                                                        and ap2.n_id_acad_apoyo is null
                                                                        and ap2.f_baja is null
                                                                        and ap2.c_identificacion = 1
                                                                        and ap2.f_graduacion is null
                                                    ) carrera_doble,
m.d_descred, ac.n_id_cur_tipoclase, NVL(decode(ap.n_id_modalidad,922, 'CABA', 923, 'CAMPUS', 924, 'CAMPUS - DH' , 925, 'CABA - DH', 1142, 'CAMPUS - CABA'),'SIN MODALIDAD') modalidad
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        cursos c,
        cursos_tipoclase ct
        where 1= 1
        and ac.n_id_alu_prog = ap.n_id_alu_prog
        and ac.n_id_materia = m.n_id_materia
        and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
        and c.n_id_curso = ct.n_id_curso
        and c.n_id_cal_periodo =:periodo
        --and ac.f_baja is null -- SI NO QUEREMOS VER LAS BAJAS COLOCAR ESTE FILTRO
        --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
        --and ac.n_id_alu_prog in (79917, 99660)
        --and ac.d_registro in ('31042')
        --AND D_DESCRED = 'D300'
        order by 1 desc, 2
       ;--16.564
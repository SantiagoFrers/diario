--INSCRIPCION BORRADOR   
SELECT to_char(ac.f_alta, 'dd/mm/yyyy') "Fecha alta", to_char(ac.f_alta,'hh24:mi') "Hora alta", ac.c_usuarioalt "Usuario alta", to_char(ac.f_actualizac, 'dd/mm/yyyy')"Fecha actualizacion", to_char(ac.f_actualizac,'hh24:mi') "Hora actualizacion", ac.c_usuarioact "Usuario actualizacion",
    ac.n_id_alu_prog, ac.d_registro, ac.n_promocion, ac.d_apellidos, ac.d_nombres, NVL(decode(ap.n_id_modalidad,922, 'CABA', 923, 'CAMPUS', 924, 'CAMPUS - DH' , 925, 'CABA - DH', 1142, 'CAMPUS - CABA'),'SIN MODALIDAD') modalidad, (Select p.d_descrip from udesa.programas p where p.c_identificacion = ac.c_identificacion and p.c_programa = ac.c_programa and p.c_orientacion = ac.c_orientacion) carrera,
    (select d_descred from materias where n_id_materia = ac.n_id_materia_01) "materia 1",
    (select d_descred from materias where n_id_materia = ac.n_id_materia_02) "materia 2",
    (select d_descred from materias where n_id_materia = ac.n_id_materia_03) "materia 3",
    (select d_descred from materias where n_id_materia = ac.n_id_materia_04) "materia 4",
    (select d_descred from materias where n_id_materia = ac.n_id_materia_05) "materia 5",
    (select d_descred from materias where n_id_materia = ac.n_id_materia_06) "materia 6"
    FROM alumnos_cursos_borrador ac,
        alumnos_programas ap
        where 1=1
        and ac.n_id_alu_prog = ap.n_id_alu_prog
        and ac.n_id_cal_periodo =:periodo
        --and ac.n_id_alu_prog in (79917, 99660)
        --and trunc(ac.f_alta) < trunc(to_date('19/07/2021'))
        --and ac.d_registro in ('31042')
        ;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSCRIPCION CONFIRMADA
SELECT to_char(ac.f_alta, 'dd/mm/yyyy') "Fecha alta", to_char(ac.f_alta,'hh24:mi') "Hora alta", ac.c_usuarioalt "Usuario alta", to_char(ac.f_actualizac, 'dd/mm/yyyy')"Fecha actualizacion", to_char(ac.f_actualizac,'hh24:mi') "Hora actualizacion", ac.c_usuarioact "Usuario actualizacion", ac.f_baja "Fecha baja",ac.n_id_alu_prog, ac.d_registro, ap.n_promocion, ap.d_apellidos, ap.d_nombres, (Select p.d_descrip from udesa.programas p where p.c_identificacion = ap.c_identificacion and p.c_programa = ap.c_programa and p.c_orientacion = ap.c_orientacion) carrera, m.d_descred, ac.n_id_cur_tipoclase, NVL(decode(ap.n_id_modalidad,922, 'CABA', 923, 'CAMPUS', 924, 'CAMPUS - DH' , 925, 'CABA - DH', 1142, 'CAMPUS - CABA'),'SIN MODALIDAD') modalidad
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
       ;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DIFERENCIA ENTRE CANTIDAD DE ALUMNOS Y CANTIDAD DE ALUMNOS INSCRIPTOS CONFIRMADOS
with inscriptos as (SELECT ap.n_promocion, count(distinct ap.n_id_persona) cant_alumnos_inscriptos
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
        and c.n_id_cal_periodo = :periodo
        --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
        and ac.f_baja is null
        group by ap.n_promocion
        order by 1),
cantidad_alumnos as (SELECT ap.n_promocion, count(distinct ap.n_id_persona) cant_alumnos
    FROM alumnos_programas ap
        where not exists (SELECT * 
                            FROM LICENCIAS l,
                                alumnos_programas ap2
                                WHERE TRUNC(f_HASTA) >= (SELECT distinct F_INICIO FROM CURSOS WHERE N_ID_CAL_PERIODO = :periodo)
                                and l.n_id_alu_prog = ap2.n_id_alu_prog
                                and ap.n_id_persona = ap2.n_id_persona) 
        and ap.c_tipo = 'Alumno'
        and ap.f_baja is null
        and ap.f_graduacion is null
        and ap.n_promocion in (select n_promocion from inscriptos)
        group by ap.n_promocion
        order by 1)

SELECT i.n_promocion, ca.cant_alumnos, i.cant_alumnos_inscriptos, (ca.cant_alumnos - i.cant_alumnos_inscriptos) pend_inscripcion, round((ca.cant_alumnos - i.cant_alumnos_inscriptos) / ca.cant_alumnos, 2) porcentaje_pendiente
    FROM inscriptos i,
        cantidad_alumnos ca
        where i.n_promocion = ca.n_promocion
        ;

--LISTADO DE ALUMNOS NO INCRIPTOS
SELECT distinct n_id_persona, n_promocion, d_registro, d_apellidos, d_nombres
    FROM alumnos_programas ap
        where not exists (SELECT * 
                            FROM LICENCIAS l,
                                alumnos_programas ap2
                                    WHERE TRUNC(f_HASTA) >= (SELECT distinct F_INICIO FROM CURSOS WHERE N_ID_CAL_PERIODO = :periodo)
                                    and l.n_id_alu_prog = ap2.n_id_alu_prog
                                    and ap.n_id_persona = ap2.n_id_persona) 
        and not exists (SELECT *
                            FROM alumnos_cursos ac,
                                alumnos_programas ap2,
                                materias m,
                                cursos c,
                                cursos_tipoclase ct
                                    where 1= 1
                                    and ap.n_id_persona = ap2.n_id_persona
                                    and ac.n_id_alu_prog = ap2.n_id_alu_prog
                                    and ac.n_id_materia = m.n_id_materia
                                    and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
                                    and c.n_id_curso = ct.n_id_curso
                                    and c.n_id_cal_periodo = :periodo
                                    and ac.f_baja is null)
        and ap.c_tipo = 'Alumno'
        and ap.f_baja is null
        and ap.f_graduacion is null
        and ap.n_promocion in (30,31,32,33);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CANTIDAD DE INSCRIPTOS POR PROMOCION Y POR CARRERA 
    --(duplica en los dobles carreras)
SELECT ap.n_promocion promocion, p.d_descrip carrera, count(distinct ap.n_id_persona) "CANT DE ALUMNOS"
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        programas p,
        cursos c,
        cursos_tipoclase ct
            where 1= 1
            and ac.n_id_alu_prog = ap.n_id_alu_prog
            and ap.c_identificacion = p.c_identificacion and ap.c_programa = p.c_programa and ap.c_orientacion = p.c_orientacion
            and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
            and c.n_id_curso = ct.n_id_curso
            and c.n_id_cal_periodo = :periodo
            and ac.n_id_materia = m.n_id_materia
            --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
            and ac.f_baja is null
            --and ap.n_promocion = 31
                group by ap.n_promocion, p.d_descrip
                ORDER BY 1, 2, 3;
                
--CANTIDAD DE INSCRIPTOS POR PROMOCION Y POR CARRERA 
    --(NO duplica en los dobles carreras, crea una nueva carrera con las combinaciones)
with datos as (SELECT ap.n_promocion promocion, (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
                                                            from    UDESA.Alumnos_Programas ap2
                                                                        where ap2.n_id_persona = AP.n_id_persona
                                                                        and ap2.c_tipo = 'Alumno'
                                                                        and ap2.n_id_acad_apoyo is null
                                                                        and ap2.f_baja is null
                                                                        and ap2.c_identificacion = 1
                                                                        and ap2.f_graduacion is null
                                                    ) carrera, ap.n_id_persona
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        cursos c,
        cursos_tipoclase ct
            where 1= 1
            and ac.n_id_alu_prog = ap.n_id_alu_prog
            and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
            and c.n_id_curso = ct.n_id_curso
            and c.n_id_cal_periodo = :periodo
            and ac.n_id_materia = m.n_id_materia
            --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
            and ac.f_baja is null
            --and ap.n_promocion = 31
                --group by ap.n_promocion, carrera
                ORDER BY 1, 2)
SELECT promocion, carrera,  count(distinct n_id_persona) "CANT DE ALUMNOS" 
    FROM datos
        group by promocion, carrera
        order by 1,2,3;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CANTIDAD DE INSCRIPTOS POR PROMOCION, POR CARRERA, POR CANTIDAD DE MATERIAS SELECCIONADAS
    --(duplica en los dobles carreras)
WITH LISTADO AS (SELECT ap.n_promocion, AC.N_ID_ALU_PROG, p.d_descrip, count(distinct ac.N_ID_MATERIA) CANT_MATERIAS
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        programas p,
        cursos c,
        cursos_tipoclase ct
            where 1= 1
            and ac.n_id_alu_prog = ap.n_id_alu_prog
            and ap.c_identificacion = p.c_identificacion and ap.c_programa = p.c_programa and ap.c_orientacion = p.c_orientacion
            and ac.n_id_materia = m.n_id_materia
            and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
            and c.n_id_curso = ct.n_id_curso
            and c.n_id_cal_periodo = :periodo
            --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
            and ac.f_baja is null
            group by ap.n_promocion, AC.N_ID_ALU_PROG, p.d_descrip)
SELECT N_PROMOCION PROMOCION, D_DESCRIP CARRERA, CANT_MATERIAS, COUNT(*) CANT_ALUMNOS
    FROM LISTADO
        GROUP BY N_PROMOCION, D_DESCRIP, CANT_MATERIAS
        ORDER BY 1,2,3,4;
        
--CANTIDAD DE INSCRIPTOS POR PROMOCION, POR CARRERA, POR CANTIDAD DE MATERIAS SELECCIONADAS        
    --(NO duplica en los dobles carreras, crea una nueva carrera con las combinaciones)
WITH LISTADO AS (SELECT ap.n_promocion, Ap.n_id_persona, (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
                                                            from    UDESA.Alumnos_Programas ap2
                                                                        where ap2.n_id_persona = AP.n_id_persona
                                                                        and ap2.c_tipo = 'Alumno'
                                                                        and ap2.n_id_acad_apoyo is null
                                                                        and ap2.f_baja is null
                                                                        and ap2.c_identificacion = 1
                                                                        and ap2.f_graduacion is null
                                                    ) carrera, ac.N_ID_MATERIA
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        programas p,
        cursos c,
        cursos_tipoclase ct
            where 1= 1
            and ac.n_id_alu_prog = ap.n_id_alu_prog
            and ap.c_identificacion = p.c_identificacion and ap.c_programa = p.c_programa and ap.c_orientacion = p.c_orientacion
            and ac.n_id_materia = m.n_id_materia
            and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
            and c.n_id_curso = ct.n_id_curso
            and c.n_id_cal_periodo = :periodo
            --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
            and ac.f_baja is null
            ),
CANT_MATERIAS AS (SELECT N_PROMOCION, n_id_persona, CARRERA, count(distinct N_ID_MATERIA) CANT_MATERIAS--, COUNT(*) CANT_ALUMNOS
    FROM LISTADO
        GROUP BY N_PROMOCION, n_id_persona, carrera
        ORDER BY 1,2,3)

SELECT N_PROMOCION PROMOCION, CARRERA, CANT_MATERIAS, COUNT(*) CANT_ALUMNOS
    FROM CANT_MATERIAS
        GROUP BY N_PROMOCION, CARRERA, CANT_MATERIAS
        ORDER BY 1,2,3,4;

----------------------------------------------------------------------------------------------------
--ALUMNOS, CARRERA Y CANTIDAD DE MATERIAS QUE SE ANOTO
with datos as (SELECT ap.n_promocion promocion,  ap.d_registro registro,  ap.d_apellidos apellido, ap.d_nombres nombre, (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
                                                            from    UDESA.Alumnos_Programas ap2
                                                                        where ap2.n_id_persona = AP.n_id_persona
                                                                        and ap2.c_tipo = 'Alumno'
                                                                        and ap2.n_id_acad_apoyo is null
                                                                        and ap2.f_baja is null
                                                                        and ap2.c_identificacion = 1
                                                                        and ap2.f_graduacion is null
                                                    ) carrera, m.d_descred materia
    FROM alumnos_cursos ac,
        alumnos_programas ap,
        materias m,
        cursos c,
        cursos_tipoclase ct
            where 1= 1
            and ac.n_id_alu_prog = ap.n_id_alu_prog
            and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
            and c.n_id_curso = ct.n_id_curso
            and c.n_id_cal_periodo = :periodo
            and ac.n_id_materia = m.n_id_materia
            --and trunc(ac.f_alta) >= trunc(to_date('17/07/2021'))
            and ac.f_baja is null
            --and ap.n_promocion = 31
                --group by ap.n_promocion, carrera
                ORDER BY 1, 2, 3, 4)
SELECT promocion, registro, apellido, nombre, carrera,  count(distinct materia) "CANT DE MATERIAS" 
    FROM datos
        group by promocion, registro, apellido, nombre, carrera
        order by 1,2,3,4,5,6;

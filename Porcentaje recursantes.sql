--ALUMNOS CURSANDO CONTRA PORCENTAJE DE RECURSADO. SE DEBERIA SUMAR ESTOS TOTALES A LOS QUE DE EL LISTADO RESUMIDO DE SILVITA
-- Lo ideal seria agregar una columna en materias con dato de porcentaje recursantes, con este se automatiza el 100%
SELECT ac.n_id_materia, m.D_DESCRED, case 
                                       when m.d_descred = 'A112' then round(count(ac.n_id_materia) * 0.2)
                                       when m.d_descred = 'A125' then round(count(ac.n_id_materia) * 0.2)
                                       when m.d_descred = 'A163' then round(count(ac.n_id_materia) * 0.2)
                                       when m.d_descred = 'A322' then round(count(ac.n_id_materia) * 0.2)
                                       ELSE round(count(ac.n_id_materia * 1))
                                     end CUENTA
    FROM v_alumnos_cursos ac,
        materias m
        where ac.n_id_materia = m.n_id_materia
        and ac.c_año_lectivo = (case when (sysdate) BETWEEN to_date('01/03', 'dd/mm') and to_date('31/12', 'dd/mm') then to_number(to_char(sysdate, 'yyyy')) else (to_number(to_char(sysdate, 'yyyy'))-1) end)
        and ac.n_periodo = (case when (sysdate) BETWEEN to_date('01/03', 'dd/mm') and to_date('31/07', 'dd/mm') then 1 else 2 end)
        and ac.c_tipo_clase = 'Teórica'
        and ac.f_baja is null
        and d_descred in('A112', 'A125', 'A163', 'A322')
        GROUP BY ac.n_id_materia, m.D_DESCRED
        order by 2;
/*
Listado con el porcentaje de desaprobados por materia del año lectivo anterior
*/
select al.n_id_materia, nvl(round((select x.aplazos 
                                    from (select al2.n_id_materia, count(*) as aplazos
                                            from alumnos_libretas al2,
                                                materias m
                                                where 1 = 1
                                                and al2.n_id_materia = m.n_id_materia
                                                and m.c_identificacion = 1
                                                and al2.c_clase_evalua = 'Final'
                                                and (al2.m_equivalencia is null or al2.m_equivalencia = 'N')
                                                and al2.m_aprueba_mat = 'No'
                                                and to_number(to_char(al2.F_RINDE, 'yyyy')) = to_number(to_char(sysdate, 'yyyy'))-1
                                                group by al2.n_id_materia
                                                order by 1) x
                                        where al.n_id_materia = x.n_id_materia) / count(*), 2), 0) as ratio
                    from    alumnos_libretas al,
                            materias m
                                where 1 = 1
                                and al.n_id_materia = m.n_id_materia
                                and m.c_identificacion = 1
                                and al.c_clase_evalua = 'Final'
                                and (al.m_equivalencia is null or al.m_equivalencia = 'N')
                                and to_number(to_char(al.F_RINDE, 'yyyy')) = to_number(to_char(sysdate, 'yyyy'))-1
                                group by al.n_id_materia
                                order by 1
;
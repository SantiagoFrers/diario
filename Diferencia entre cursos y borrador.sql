SELECT ap.n_id_persona, ap.d_apellidos, ap.D_NOMBRES, ap.C_IDENTIFICACION, ap.C_PROGRAMA, ap.C_ORIENTACION, ap.C_PLAN, ac.n_id_alu_prog, ac.C_CONDICION_CURSADA, ac.d_registro, ap.n_promocion, ac.n_id_materia, decode(ct.c_tipo_clase,'Teórica', '1 - Teórica', 'Tutorial','2 - Tutorial', 'Clase de Problemas', '3 - Clase de Problemas') c_tipo_clase, ac.n_id_cur_tipoclase, ac.n_id_cupo_curso, ac.n_id_alu_cur -- COMENTAR PARA VER EL TOTAL PARA VER EL TOTAL POR N_ID_ALU_PROG
--SELECT ac.n_id_alu_prog, ap.n_promocion, count(ac.n_id_materia) cant_materias--COMENTAR PARA TIRAR EL DETALLE, DESCOMENTAR PARA VER TOTAL POR N_ID_ALU_PROG
    FROM alumnos_cursos ac,
        cursos c,
        cursos_tipoclase ct,
        alumnos_programas ap
            WHERE NOT EXISTS ( SELECT 1 FROM 
                                (SELECT acb1.n_id_alu_prog, n_id_materia_01 
                                    FROM alumnos_cursos_borrador acb1
                                        where n_id_cal_periodo =:PERIODO
                                UNION ALL 
                                SELECT acb1.n_id_alu_prog, n_id_materia_02 
                                    FROM alumnos_cursos_borrador acb1
                                        where n_id_cal_periodo =:PERIODO
                                UNION ALL 
                                SELECT acb1.n_id_alu_prog, n_id_materia_03 
                                    FROM alumnos_cursos_borrador acb1
                                        where n_id_cal_periodo =:PERIODO
                                UNION ALL 
                                SELECT acb1.n_id_alu_prog, n_id_materia_04 
                                    FROM alumnos_cursos_borrador acb1
                                        where n_id_cal_periodo =:PERIODO
                                UNION ALL 
                                SELECT acb1.n_id_alu_prog, n_id_materia_05 
                                    FROM alumnos_cursos_borrador acb1
                                        where n_id_cal_periodo =:PERIODO
                                UNION ALL 
                                SELECT acb1.n_id_alu_prog, n_id_materia_06 
                                    FROM alumnos_cursos_borrador acb1
                                        where n_id_cal_periodo =:PERIODO) X
                                        WHERE AC.N_ID_ALU_PROG = X.N_ID_ALU_PROG
                                        AND AC.N_ID_MATERIA = X.N_ID_MATERIA_01)        
            and ac.n_id_cur_tipoclase = ct.n_id_cur_tipoclase
            and ac.n_id_alu_prog = ap.n_id_alu_prog
            and c.n_id_curso = ct.n_id_curso
            and c.n_id_cal_periodo =:PERIODO
            and ap.c_identificacion = 1
            --and ac.n_id_alu_prog in (79917, 99660)
            and ac.f_baja is null
                 --group by ac.n_id_alu_prog, ap.n_promocion --COMENTAR PARA TIRAR EL DETALLE, DESCOMENTAR PARA VER TOTAL POR N_ID_ALU_PROG
                order by ac.n_id_alu_prog, ac.n_id_materia, c_tipo_clase -- COMENTAR PARA TIRAR EL AGRUPADO
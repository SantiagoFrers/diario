SELECT distinct ac.d_registro "Registro", ap.d_apellidos "Apellido", ap.d_nombres "Nombre", (select nvl(Listagg(co2.c_email, ';') Within Group (Order By 1), '---') from correos co2 where co2.n_id_persona = ap.n_id_persona) "E-mails"
    FROM alumnos_cursos ac,
        alumnos_programas ap
        where ac.n_id_alu_prog = ap.n_id_alu_prog
        and ac.f_baja is null
        and ac.d_registro != :registro
        and n_id_cur_tipoclase in (SELECT ac2.n_id_cur_tipoclase
                                        FROM clases c, 
                                            cursos_horarios ch,
                                            alumnos_cursos ac2
                                            where c.n_id_cur_horario = ch.n_id_cur_horario
                                            and ch.n_id_cur_tipoclase = ac2.n_id_cur_tipoclase
                                            and ac2.f_baja is null
                                            and trunc(f_clase) BETWEEN trunc(to_date(:fecha, 'dd/mm/yyyy') -2 ) and trunc(to_date(:fecha, 'dd/mm/yyyy'))
                                            and d_registro = :registro
                                            )
        order by 1
;

SELECT *--distinct d_registro
    FROM alumnos_cursos 
        where n_id_cur_tipoclase in (78510, 78511, 79031, 78818, 78436, 78510, 78437);
        
        

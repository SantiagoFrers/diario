
--VALIDACION DE SI HAY EVENTOS EN ESA AULA Y RANGO FECHA/HORA
--select x.fecha, x.n_hora_desde, x.n_hora_hasta, x.n_id_espacio
select count(*) cant_eventos
    from (SELECT aa.f_actividad fecha, aa.n_hora_desde, aa.n_hora_hasta, ea.n_id_espacio
            FROM espacios_asignados ea 
                join actividades_academicas aa on ea.n_id_academica = aa.n_id_academica
            UNION ALL
          SELECT c.f_clase fecha, c.n_hora_desde, c.n_hora_hasta, ea.n_id_espacio
            FROM espacios_asignados ea 
                join clases c on ea.n_id_clase = c.n_id_clase) x

        where 1 = 1
        and x.n_id_espacio = :n_id_espacio
        and x.fecha between :fecha_desde and :fecha_hasta
        and (:hora_desde between x.n_hora_desde + 1 and x.n_hora_hasta -1
        or :hora_hasta between x.n_hora_desde + 1 and x.n_hora_hasta -1)
            order by 1 desc
;

SELECT f_actividad, n_hora_desde, n_hora_hasta, n_id_espacio
    FROM actividades_academicas aa,
        espacios_asignados ea
        where 1 = 1
        and aa.n_id_academica = ea.n_id_academica
        and aa.d_Descrip = 'F405 - FINANZAS CORPORATIVAS'
        ;

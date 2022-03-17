select to_char(v.id) id,
       v.f_desde,
       to_char(v.f_desde,'DAY')dia_semana,
       substr(lpad(v.n_hora_desde,4,0),1,2) || ':' || substr(lpad(v.n_hora_desde,4,0),3,2) v_hora_desde,
       substr(lpad(v.n_hora_hasta,4,0),1,2) || ':' || substr(lpad(v.n_hora_hasta,4,0),3,2) v_hora_hasta,
       e.d_descred espacio,
       e.n_piso, 
       s.d_descrip sede,
       f.d_descrip edificio,
       case v.tipo
        when 'Reserva' then devuelve_desc_esp_cartelera(v.n_id_clase)
        else devuelve_desc_esp_asignado(v.id) -- TODO MODIFICAR CREAR UNA FUNCION PARA REEMPLAZAR ESTA
       end desc_asignacion,
       v.d_unidad,
       v.tipo tipo,
       cl.cantidad_inscriptos,
       e.n_capacidad_maxima capacidad,
       c_tipo_dictado,
       v.centro_costos
  from v_espacios_asignados v
  left join (select cl.n_id_clase, count(ac.n_id_alu_prog) cantidad_inscriptos
               from vw_clases cl
               left join udesa.alumnos_cursos ac on ac.n_id_cur_tipoclase = cl.n_id_cur_tipoclase and ac.f_baja is null
              group by cl.n_id_clase
            ) cl on cl.n_id_clase = v.n_id_clase
  join espacios e on e.n_id_espacio = v.n_id_espacio
  join edificios f on f.n_edificio = e.n_edificio
                  and f.n_sede = e.n_sede
  join sedes s on s.n_sede = f.n_sede
 where s.n_sede = nvl(:p1_sede,s.n_sede)
   --and f.n_edificio =  nvl(:p1_edificio,f.n_edificio)
   --and (v.tipo = :p1_actividades or :p1_actividades = 'Todos')
   --and (devuelve_dia_semana_letras(trunc(v.f_desde),'Castellano') = :p1_dias_semana or :p1_dias_semana = 'nulo')
   and v.f_desde = trunc(sysdate)
   and to_number(v.n_hora_desde) > to_number(to_char(SYSDATE, 'hh24mi'))
   --and :p1_espacios = 1 --Asignados
   order by 4, 5


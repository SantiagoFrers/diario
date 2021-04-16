/*LISTADO DE MATERIAS PENDIENTES ALUMNOS GRADO
Segun pedido se colocaron 4 filtros
    1) Promocion: Colocar el numero de promocion a consultar
    2) nro_semestre_inscripcion: Colocar 1 o 2 segun indicando el numero de cuatrimestre al que se estaria inscribiendo
    3) año_plan: Colocar el año hasta que materias se deben mostrar. Ej La promocion 32 nacio el 2020, en el 2021 se deberia poner 2 y nos muestra las materias de 2 y 1 año
    4) sede: Filtrar por Victoria o CABA
    
Se pueden sacar 2 listados
    1) SELECT * FROM listado_final; Listado con detalle del alumno
    2) SELECT * FROM resumen; Listado con el resumen de cantidad de alumnos por materia
    
*/


with planes as (SELECT  pg.c_identificacion || '-' || pg.c_programa || '-' || pg.c_orientacion || '-' || pg.c_plan as plan1, pg.c_identificacion || '-' || pg.c_programa || '-' || pg.c_orientacion as IPO1,
                        pg.d_observ, pg.n_grupo, pg.c_tipo_materias, pg.n_req_cantidad, pg.n_req_credito, pm.n_id_materia, pm."N_AÑO_CARRERA"
                        , decode(pm.c_dictado, '0', 'Ocasional', 'I', 'Indistinto', '1', '1° Semestre', '2', '2° Semestre', 'Dato vacio') dictado, pm.n_credito
    FROM    planes_grupos pg,
            planes_materias pm
                where pg.n_id_grupo = pm.n_id_grupo
                and pg.c_identificacion = 1 -- Se filtra por grado
                and pg.m_tipo_grupo != 'G' -- Son los grupos de la carrera en si
                ),
    
--LISTADO DE ALUMNOS ACTIVOS CON LAS MATERIAS DE SU CARRERA
activos as (SELECT      ap.d_apellidos, ap.d_nombres, ap.d_registro, ap.n_promocion, ap.N_ID_ALU_PROG, ap.n_id_persona,
                        ap.c_identificacion || '-' || ap.c_programa || '-' || ap.c_orientacion || '-' || ap.c_plan as plan2,
                        ap.c_identificacion || '-' || ap.c_programa || '-' || ap.c_orientacion as IPO
                        , ap.c_vinculo, ap.c_identificacion, ap.c_programa, ap.c_orientacion, decode(ap.n_id_modalidad, '922', 'CABA', '923', 'Victoria', '924', 'Victoria', '925', 'CABA', '1142', 'Victoria', 'Sin modalidad') as sede

    FROM    alumnos_programas ap
                where ap.c_tipo = 'Alumno' 
                and ap.c_identificacion = 1 --Alumnos de grado
                -- Se quita los filtros de baja y graduacion en esta parte y se agregan al final, ya que sino no podemos ver las materias aprobadas de estos n_id_alu_prog de las carreras egresadass o cambios de carrera
                /*and ap.f_baja is  null -- no este de baja
                --and ap.f_graduacion is  null -- no este graduado */
                and ap.n_promocion = :promocion
                --and ap.d_registro = 30323 -- TODO borrar cuando se acaben las pruebas
                --and ap.d_registro = 28059 -- TODO borrar cuando se acaben las pruebas
                --and ap.d_registro = 30010 -- TODO borrar cuando se acaben las pruebas
                ), 

--LISTADO DE ALUMNOS ACTIVOS CON LAS MATERIAS DE SUS PLANES
planes_activos as (SELECT a.*,p.* ,m.D_DESCRED, m.d_descrip
    FROM    activos a,
            planes p,
            materias m
                where a.plan2 = p.plan1
                and p.n_id_materia = m.n_id_materia
                ),

------------------------------------------------------------------------------------------------------
--Nuevo - Ver de reemplazar el de aprobadas
--LISTADO DE MATERIAS APROBADAS Y EN CURSO CON N_ID_PERSONA
listado_union as (select a.d_apellidos, a.d_nombres, a.d_registro, a.n_promocion, a.n_id_alu_prog, a.n_id_persona, /*a.plan2,*/ al.n_id_materia
                    from    alumnos_libretas al,
                            activos a
                                where a.N_ID_ALU_PROG = al.N_ID_ALU_PROG
                                and al.c_clase_evalua = 'Final'
                                and al.m_aprueba_mat = 'Si'

                UNION ALL

                  select a.d_apellidos, a.d_nombres, a.d_registro, a.n_promocion, a.n_id_alu_prog, a.n_id_persona, /*a.plan2,*/ ac.n_id_materia
                    from    v_alumnos_cursos ac,
                            activos a
                                where a.N_ID_ALU_PROG = ac.N_ID_ALU_PROG
                                and ac.c_año_lectivo = (case when (sysdate) BETWEEN to_date('01/03', 'dd/mm') and to_date('31/12', 'dd/mm') then to_number(to_char(sysdate, 'yyyy')) else (to_number(to_char(sysdate, 'yyyy'))-1) end)
                                and ac.n_periodo = (case when (sysdate) BETWEEN to_date('01/03', 'dd/mm') and to_date('31/07', 'dd/mm') then 1 else 2 end)
                                and ac.c_tipo_clase = 'Teórica'
                ),

--LISTADO DE MATERIAS APROBADAS DE ALUMNOS POR ALUMNO (SIRVE PARA LAS DOBLES)
materias_aprobadas_alumno as (SELECT DISTINCT lu.d_apellidos, lu.d_nombres, lu.d_registro, lu.n_promocion, lu.n_id_alu_prog, lu.n_id_persona, /*a.plan2,*/ pa.n_grupo, pa.n_req_cantidad, lu.n_id_materia, pa.n_año_carrera, pa.dictado, pa.n_credito
    FROM    listado_union lu,
            planes_activos pa
                where lu.n_id_materia = pa.n_id_materia
                and lu.n_id_persona = pa.n_id_persona
                            ),

--LISTADO DE MATERIAS PENDIENTES
materias_pendientes as (select *
    from    planes_activos pa 
                where not exists (select * from materias_aprobadas_alumno ma where ma.n_id_materia = pa.n_id_materia
                and pa.N_ID_PERSONA = ma.N_ID_PERSONA)
                ),

--CONTEO DE GRUPOS
conteo_grupos_aprobadas as (select d_apellidos, d_nombres, n_promocion, n_id_persona, d_registro, n_grupo, 
    sum(nvl(n_credito, 1)) as cuenta
    --COUNT(*) as cuenta
    from    materias_aprobadas_alumno
    group by d_apellidos, d_nombres, n_promocion, n_id_persona, d_registro, n_grupo
                ),
                
--LISTADO DE MATERIAS PENDIENTES CON CONTEO DE GRUPOS INCLUIDO
    --Se agrega en esta parte el filtro para que solo muestre carreras activas
materias_pendientes_conteo as (select mp.*
    from    materias_pendientes mp,
            alumnos_programas ap
                where not exists (select * from conteo_grupos_aprobadas cga
                where mp.n_id_persona = cga.n_id_persona
                and mp.n_grupo = cga.n_grupo
                and mp.n_req_cantidad <= cga.cuenta 
                and mp.n_req_credito <= cga.cuenta)
                and mp.N_ID_ALU_PROG = ap.N_ID_ALU_PROG
                and ap.f_baja is  null -- no este de baja
                and ap.f_graduacion is  null -- no este graduado 
                ),

--LISTADO MATERIAS PENDIENTES FINAL SIN CONTEMPLAR CORRELATIVAS - SE DUPLICA LAS MATERIAS QUE ESTEN EN AMBOS PLANES PERO DISTINTOS GRUPOS, APLICA EN DOBLES TITULACIONES
listado_sin_correlativas as (SELECT DISTINCT mpc.N_ID_PERSONA, mpc.D_REGISTRO, mpc.N_PROMOCION, mpc.D_APELLIDOS, mpc.D_NOMBRES, 
                                (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
                                    from    UDESA.Alumnos_Programas ap2
                                                where ap2.n_id_persona = mpc.n_id_persona
                                                and ap2.c_tipo = 'Alumno'
                                                and ap2.n_id_acad_apoyo is null
                                                and ap2.f_baja is null
                                                and ap2.c_identificacion = 1
                                                and ap2.f_graduacion is null
                                                )programa_2,
                                        --Se deja comentado ya que Silvia no lo necesita, lo usamos para testear por grupo de materia
                                        mpc.N_GRUPO, mpc.D_OBSERV, mpc.C_TIPO_MATERIAS, mpc.N_REQ_CANTIDAD, mpc.N_REQ_CREDITO, nvl(mga.cuenta,0) conteo_actual,(mpc.N_REQ_CANTIDAD + mpc.N_REQ_CREDITO - nvl(mga.cuenta,0)) pendiente,
                                        mpc.N_ID_MATERIA, mpc.D_DESCRED, 
                                        --mpc.N_AÑO_CARRERA, -- Se quita ya en caso puede duplicar materias que esten en 2 carreras en años distintos
                                        mpc.DICTADO, mpc.sede
    FROM    materias_pendientes_conteo mpc
            left join conteo_grupos_aprobadas mga on mpc.N_ID_PERSONA = mga.N_ID_PERSONA
                and mpc.n_grupo = mga.n_grupo
                where mpc.dictado != 'Ocasional'
                and (mpc.dictado = (:nro_semestre_inscripcion || '° Semestre') or mpc.dictado = 'Indistinto') -- Semestre al cual se estan inscribiendo
                and mpc.N_AÑO_CARRERA <= :año_plan -- Año de las materias que deberia ver para la inscripcion mas las que adeude
                and sede = :sede or sede = 'Sin modalidad' -- Victoria o CABA
                order by mpc.D_REGISTRO, mpc.D_APELLIDOS, mpc.D_NOMBRES, mpc.D_DESCRED
                ),

--LISTADO DE MATERIAS CORRELATIVAS PARA CURSAR
materias_correlativas as (select DISTINCT mpc.N_ID_PERSONA, mpc.D_REGISTRO, mpc.N_ID_MATERIA, mpc.D_DESCRED, udesa.pak_inscripcion_cursos.check_correlativas(mpc.N_ID_ALU_PROG, mpc.D_REGISTRO, mpc.N_ID_MATERIA,'S') correlativa
    from materias_pendientes_conteo mpc
                where mpc.dictado != 'Ocasional'
                ),

--LISTADO FINAL PARA ALUMNOS
listado_final as (select *
    from    listado_sin_correlativas lo
                where exists (select * from materias_correlativas mc
                where lo.n_id_persona = mc.n_id_persona
                and lo.n_id_materia = mc.n_id_materia
                and mc.correlativa = 'TRUE'
                )),
                
listado_diferencia_modulos as (select *
    from listado_final lf
                where c_tipo_materias = 'OBLIGATORIO'
                
                UNION ALL
                
                select distinct n_id_persona, d_registro, n_promocion, d_apellidos, d_nombres, programa_2, n_grupo, d_observ, c_tipo_materias, n_req_cantidad, n_req_credito, conteo_actual, pendiente, null as n_id_materia, null as d_descred, null as dictado, sede
    from listado_final lf
                where c_tipo_materias = 'ELECTIVO' 
                or c_tipo_materias = 'OPTATIVO'
                ),

--LISTADO RESUMEN POR MATERIA CANTIDAD DE ALUMNOS
resumen as (select n_promocion, programa_2, d_descred, sede, count(*) as "Total de alumnos"
    from    listado_final lf
                GROUP BY n_promocion, programa_2, d_descred, sede
                ORDER BY D_DESCRED, N_PROMOCION
                )

select * from listado_diferencia_modulos;
select * from listado_final;
SELECT * FROM resumen;

SELECT * FROM conteo_grupos_aprobadas;
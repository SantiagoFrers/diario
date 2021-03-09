with planes as (SELECT  pg.c_identificacion || '-' || pg.c_programa || '-' || pg.c_orientacion || '-' || pg.c_plan as plan1, pg.c_identificacion || '-' || pg.c_programa || '-' || pg.c_orientacion as IPO1,
                        pg.d_observ, pg.n_grupo, pg.c_tipo_materias, pg.n_req_cantidad, pg.n_req_credito, pm.n_id_materia, pm."N_AÑO_CARRERA"
                        , decode(pm.c_dictado, '0', 'Ocasional', 'I', 'Indistinto', '1', '1° Semestre', '2', '1° Semestre', 'Dato vacio') dictado, pm.n_credito
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
                        , ap.c_vinculo, ap.c_identificacion, ap.c_programa, ap.c_orientacion, decode(ap.n_id_modalidad, '922', 'CABA', '923', 'Victoria', '924', 'Victoria', '925', 'CABA', 'Sin modalidad') as sede

    FROM    alumnos_programas ap
                where ap.c_tipo = 'Alumno' 
                and ap.c_identificacion = 1 --Alumnos de grado
                and ap.f_baja is  null -- no este de baja
                and ap.f_graduacion is  null -- no este graduado
                and ap.n_promocion = :promocion
                and ap.d_registro = 31343 -- TODO sacar este registro
                --and ap.d_registro = 28059 -- TODO sacar este registro
                ), 

--LISTADO DE ALUMNOS ACTIVOS CON LAS MATERIAS DE SUS PLANES
planes_activos as (SELECT a.*,p.* ,m.D_DESCRED, m.d_descrip
    FROM    activos a,
            planes p,
            materias m
                where a.plan2 = p.plan1
                and p.n_id_materia = m.n_id_materia
                ),

--LISTADO DE MATERIAS APROBADAS DE ALUMNOS POR CARRERA
materias_aprobadas_carrera as (select *
    from    planes_activos pa
                where exists (select * from alumnos_libretas al where al.n_id_materia = pa.n_id_materia
                and pa.N_ID_ALU_PROG = al.N_ID_ALU_PROG
                and al.c_clase_evalua = 'Final'
                and al.m_aprueba_mat = 'Si'
                )),
                
--LISTADO DE MATERIAS EN CURSO, BUSCA AUTOMATICAMENTO EN EL SEMESTRE EN CURSO 01/03 A 31/07 1°SEMESTRE Y 01/08 A 28/02 2°SEMESTRE
materias_curso as (select *
    from    planes_activos pa
                where exists (select * from v_alumnos_cursos ac where ac.n_id_materia = pa.n_id_materia
                and pa.N_ID_ALU_PROG = ac.N_ID_ALU_PROG
                and ac.c_año_lectivo = (case when (sysdate) BETWEEN to_date('01/03', 'dd/mm') and to_date('31/12', 'dd/mm') then to_number(to_char(sysdate, 'yyyy')) else (to_number(to_char(sysdate, 'yyyy'))-1) end)
                and ac.n_periodo = (case when (sysdate) BETWEEN to_date('01/03', 'dd/mm') and to_date('31/07', 'dd/mm') then 1 else 2 end)
                and ac.c_tipo_clase = 'Teórica'
                )),

--LISTADO UNION ENTRE EL LISTADO DE MATERIAS APROBADAS POR ALUMNO Y MATERIAS EN CURSO

listado_union as (SELECT * 
    FROM table -- crear el listado de union y luego llevar al listado siguiente en reemplazo materias_aprobadas_carrera
                ),

--LISTADO DE MATERIAS APROBADAS DE ALUMNOS POR ALUMNO (SIRVE PARA LAS DOBLES)
materias_aprobadas_alumno as (SELECT DISTINCT ma.d_apellidos, ma.d_nombres, ma.d_registro, ma.n_promocion, ma.n_id_alu_prog, ma.n_id_persona, ma.plan1, pa.n_grupo, ma.n_req_cantidad, ma.n_id_materia, ma.n_año_carrera, ma.dictado, pa.n_credito --TODO pa agregado
    FROM    materias_aprobadas_carrera ma,
            planes_activos pa
                where ma.n_id_materia = pa.n_id_materia
                and ma.n_id_persona = pa.n_id_persona
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
materias_pendientes_conteo as (select *
    from    materias_pendientes mp
                where not exists (select * from conteo_grupos_aprobadas cga
                where mp.n_id_persona = cga.n_id_persona
                and mp.n_grupo = cga.n_grupo
                and mp.n_req_cantidad <= cga.cuenta 
                and mp.n_req_credito <= cga.cuenta)
                ),
                            
/* TODO BORRAR 
------------------------------------------------------------------------------------                

--LISTADO DE PROGRAMAS
listado_programas_alumnos as (SELECT pr.c_identificacion || '-' || pr.c_programa || '-' || pr.c_orientacion as IPO2, pr.d_descrip programa
    FROM    programas pr
                ),
                
--LISTADO DE IPO ACTIVOS
carrera_activa as (SELECT DISTINCT n_id_persona, IPO programa
    FROM activos ap
                where (c_vinculo = 'A' or c_vinculo = 'FF')-- TODO RE VERIFICAR LOS CASOS DE FIN DE FACTURACION DE UNA CARRERA Y ACTIVOS EN OTROS COMO DIFERENCIARLOS?
                ),

--LISTADO FINAL, LISTADO DE MATERIAS PENDIENTES PARA INSCRIPCION DE SILVIA
listado_ordenado as (SELECT DISTINCT mpc.N_ID_PERSONA, mpc.D_REGISTRO, mpc.N_PROMOCION, mpc.D_APELLIDOS, mpc.D_NOMBRES, lpa.programa, mpc.N_GRUPO, mpc.D_OBSERV, mpc.C_TIPO_MATERIAS, mpc.N_REQ_CANTIDAD, mpc.N_REQ_CREDITO, mpc.N_ID_MATERIA, mpc.D_DESCRED, mpc.N_AÑO_CARRERA, mpc.DICTADO
    FROM    materias_pendientes_conteo mpc,
            carrera_activa ca,
            listado_programas_alumnos lpa
                where mpc.n_id_persona = ca.n_id_persona
                and ca.programa = lpa.IPO2
                and mpc.dictado != 'Ocasional'
                --and (mpc.dictado = (:Nro_Semestre || '° Semestre') or mpc.dictado = 'Indistinto') -- TODO DESCOMENTAR CUANDO ESTE 100% TESTEADO
                order by mpc.N_GRUPO
                ),
            
--LISTADO CON LAS DOS CARRERAS - SE DUPLICA LAS MATERIAS EN AMBOS PLANES
listado_ordenado_con_carrera as (SELECT *
-- lo comento para que Ale pueda ver que trae la tabla mpc.N_ID_PERSONA, mpc.D_REGISTRO, mpc.N_PROMOCION, mpc.D_APELLIDOS, pa.programa //ESTE ES EL DATO QUE HACE QUE SE DUPLIQUE // , mpc.D_NOMBRES, mpc.N_GRUPO, mpc.D_OBSERV, mpc.C_TIPO_MATERIAS, mpc.N_REQ_CANTIDAD, mpc.N_REQ_CREDITO, mpc.N_ID_MATERIA, mpc.D_DESCRED, mpc.N_AÑO_CARRERA, mpc.DICTADO
    FROM    materias_pendientes_conteo mpc,
            listado_programas_alumnos pa
                where mpc.ipo1 = pa.ipo2
                and mpc.dictado != 'Ocasional'
                order by mpc.N_GRUPO
                ),

--LISTADO DE CANTIDAD DE MATERIAS POR ALUMNO -- SIRVE PARA IDENTIFICAR LAS MATERIAS DE DISTINTOS PLANES QUE PERTENECEN A UN MISMO ALUMNO
materias_duplicadas as (select DISTINCT mpc.N_ID_PERSONA, mpc.N_ID_MATERIA, count (*) conteo
    FROM materias_pendientes_conteo mpc
                where mpc.dictado != 'Ocasional'
                GROUP BY mpc.N_ID_PERSONA, mpc.N_ID_MATERIA
                ),
--------------------------------------------------------------------------------------------- */

--LISTADO FINAL PARA SILVIA - SE DUPLICA LAS MATERIAS QUE ESTEN EN AMBOS PLANES PERO DISTINTOS GRUPOS, APLICA EN DOBLES TITULACIONES
listado_ordenado as (SELECT DISTINCT mpc.N_ID_PERSONA, mpc.D_REGISTRO, mpc.N_PROMOCION, mpc.D_APELLIDOS, mpc.D_NOMBRES, 
                                (select nvl(Listagg(UDESA.Devuelve_Desc_Programa(ap2.c_identificacion, ap2.c_programa, ap2.c_orientacion), '/ ') Within Group (Order By 1), '---')prog2
                                    from    UDESA.Alumnos_Programas ap2
                                                where ap2.n_id_persona = mpc.n_id_persona
                                                --and ap2.n_id_alu_prog != mpc.n_id_alu_prog --TODO BORRAR CUANDO ESTE 100% TESTEADO
                                                and ap2.c_tipo = 'Alumno'
                                                and ap2.n_id_acad_apoyo is null
                                                and ap2.f_baja is null
                                                and ap2.c_identificacion = 1
                                                and ap2.f_graduacion is null
                                                )programa_2,
                /*mpc.N_GRUPO, mpc.D_OBSERV, mpc.C_TIPO_MATERIAS, mpc.N_REQ_CANTIDAD, mpc.N_REQ_CREDITO, */ mpc.N_ID_MATERIA, mpc.D_DESCRED, mpc.N_AÑO_CARRERA, mpc.DICTADO, mpc.sede
    FROM    materias_pendientes_conteo mpc
                where mpc.dictado != 'Ocasional'
                and (mpc.dictado = (:nro_semestre || '° Semestre') or mpc.dictado = 'Indistinto') -- TODO DESCOMENTAR CUANDO ESTE 100% TESTEADO
                and mpc.N_AÑO_CARRERA = :año_plan
                --and sede = :sede -- Victoria o CABA
                order by mpc.D_REGISTRO, mpc.D_APELLIDOS, mpc.D_NOMBRES, mpc.D_DESCRED
                )
              
SELECT * FROM materias_aprobadas_alumno;
SELECT * FROM listado_ordenado;
--SELECT * FROM materias_duplicadas;
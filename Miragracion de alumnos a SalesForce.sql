SELECT p.n_id_persona, 
    p.d_apellidos "Apellido", 
    p.d_nombres "Nombre", 
    p.c_tipo_documento "Tipo documento", 
    p.n_documento "Nro documento",
    p.n_cuit CUIT,
    p.n_pasaporte "Pasaporte", 
--Mails existentes, uno en cada columna
    (select c_email from correos c where p.n_id_persona = c.n_id_persona and c_correo = 'Laboral') "Email laboral",
    (select c_email from correos c where p.n_id_persona = c.n_id_persona and c_correo = 'E-Mail Interno') "Email interno",
    (select c_email from correos c where p.n_id_persona = c.n_id_persona and c_correo = 'e-mail 1') "Email 1",
    (select c_email from correos c where p.n_id_persona = c.n_id_persona and c_correo = 'e-mail 2') "Email 2",

--Telefonos existentes, uno en cada columna
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Celular') "Celular",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Celular 1') "Celular 1",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Familiar 1') "Telefono familiar 1",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Familiar 2') "Telefono familiar 2",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Fax Laboral 1') "Fax Laboral 1",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Fax Particular 1') "Fax Particular 1",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Laboral 1') "Telefono laboral 1",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Particular 1') "Telefono particular 1",
    (select n_telefono from telefonos t where p.n_id_persona = t.n_id_persona and c_telefono = 'Particular 2') "Telefono particular 2",
    
--Datos de direccion
    (select d.d_direccion || ' ' || d.n_direccion from direcciones d where p.n_id_persona = d.n_id_persona and d.c_domicilio = p.m_envio) "Direccion",
    (select d.c_postal from direcciones d where p.n_id_persona = d.n_id_persona and d.c_domicilio = p.m_envio) "CP",
    (select d_localidad from direcciones d, localidades where p.n_id_persona = d.n_id_persona and localidades.n_id_localidad = d.n_id_localidad and d.c_domicilio = p.m_envio) "Localidad",
    (select d_provincia from direcciones d, provincias where p.n_id_persona = d.n_id_persona and provincias.n_id_provincia = d.n_id_provincia and d.c_domicilio = p.m_envio) "Provincia",
    (select d_pais from direcciones d, paises where p.n_id_persona = d.n_id_persona and paises.n_id_pais = d.n_id_pais and d.c_domicilio = p.m_envio) "Pais",
    to_date(f_nacimiento, 'dd/mm/yy') "Fecha de nacimiento",
    m_sexo "Sexo",
    c_nacionalidad "Nacionalidad"                
        FROM personas p
            where exists (SELECT n_id_persona FROM alumnos_programas ap where p.n_id_persona = ap.n_id_persona and ap.c_tipo = 'Alumno')
            ;
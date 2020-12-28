-- create database 
-- Caso haja necessidade de criar o banco de dados
-- executar os comandos abaixo.
create database nw_base_teste;


--Function -> Trigger

CREATE FUNCTION public.fc_usa_trg_base_teste()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN

        IF (TG_OP = 'UPDATE') OR (TG_OP ='INSERT') THEN
			-- INSERE na TABLE base_teste os pedidos corretos
			INSERT INTO base_teste (CPF, PRIVATE, INCOMPLETO, DATA_DA_ULTIMA_COMPRA, TICKET_MEDIO, TICKET_DA_ULTIMA_COMPRA, LOJA_MAIS_FREQUENTE, LOJA_DA_ULTIMA_COMPRA)
			(SELECT fc_remove_acento(substring(dados, 0, 19)) AS CPF
				 , cast(fc_remove_acento(substring(dados, 19, 12)) as integer ) AS PRIVATE
				 , cast(fc_remove_acento(substring(dados, 31, 12)) as integer ) AS INCOMPLETO
				 , cast(fc_remove_acento(substring(dados, 43, 22)) as date ) AS DATA_DA_ULTIMA_COMPRA
				 , cast(fc_converte_money(substring(dados, 65, 22)) as real ) AS TICKET_MEDIO
				 , cast(fc_converte_money(substring(dados, 87, 24)) as real ) AS TICKET_DA_ULTIMA_COMPRA
				 , fc_remove_acento(substring(dados, 111, 20)) AS LOJA_MAIS_FREQUENTE
				 , fc_remove_acento(substring(dados, 131)) AS LOJA_DA_ULTIMA_COMPRA
			from fileuploaded
			where dados not like '%NULL%' 
			  and dados not like '%CPF%');
			  
			-- INSERE NA TABLE base_teste_rejected OS VALORES NULOS
		    INSERT INTO base_teste_rejected (CPF, CPF_VALIDO, PRIVATE, INCOMPLETO, DATA_DA_ULTIMA_COMPRA, TICKET_MEDIO, TICKET_DA_ULTIMA_COMPRA, LOJA_MAIS_FREQUENTE, LOJA_MAIS_FREQUENTE_VALIDO, LOJA_DA_ULTIMA_COMPRA, LOJA_DA_ULTIMA_COMPRA_VALIDO)
		    (SELECT cast(fc_remove_acento(substring(dados, 0, 19))  as varchar) AS CPF
			 	  , fc_valida_cpf(fc_remove_acento(substring(dados, 0, 19))) AS CPF_VALIDO
				  , cast(fc_remove_acento(substring(dados, 19, 12)) as integer) AS PRIVATE
				  , cast(fc_remove_acento(substring(dados, 31, 12)) as integer) AS INCOMPLETO
				  , cast(fc_remove_acento(substring(dados, 43, 22)) as varchar) AS DATA_DA_ULTIMA_COMPRA
				  , cast(fc_remove_acento(substring(dados, 65, 22)) as varchar) AS TICKET_MEDIO
				  , cast(fc_remove_acento(substring(dados, 87, 24)) as varchar) AS TICKET_DA_ULTIMA_COMPRA
			      , fc_remove_acento(substring(dados, 111, 20)) AS LOJA_MAIS_FREQUENTE
				  , fc_valida_cnpj(fc_remove_acento(substring(dados, 111, 20))) LOJA_MAIS_FREQUENTE_VALIDO
				  , fc_remove_acento(substring(dados, 131)) AS LOJA_DA_ULTIMA_COMPRA
			 	  , fc_valida_cnpj(fc_remove_acento(substring(dados, 131))) AS LOJA_DA_ULTIMA_COMPRA_VALIDO
			 from fileUploaded
			 where dados like '%NULL%' 
			   and dados not like '%CPF%');
			   
			 -- FAZ BACKUP DOS DADOS BRUTOS   
			 INSERT INTO FILEUPLOADED_BACKUP (DADOS, DATA_UPLOAD) 
			(SELECT DADOS, TO_CHAR(now(), 'DD/MM/YYYY HH24:MI:SS') as DATA_UPLOAD FROM FILEUPLOADED);
			-- LIMPA A TABLE DE UPLOAD DO ARQUIVO
			DELETE
			FROM fileuploaded;
			RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$BODY$;

ALTER FUNCTION public.fc_usa_trg_base_teste()
    OWNER TO postgres;

	
-- Function
CREATE OR REPLACE FUNCTION public.fc_converte_money(
	ds_expressao character varying)
    RETURNS character varying
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
select
replace(trim($1),',','.');
$BODY$;

ALTER FUNCTION public.fc_converte_money(character varying)
    OWNER TO postgres;


CREATE OR REPLACE FUNCTION public.fc_remove_acento(
	ds_expressao character varying)
    RETURNS character varying
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
select
translate(trim($1),'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÕÔÖóòôõöÚÙÛÜúùûüÇç','AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc');
$BODY$;

ALTER FUNCTION public.fc_remove_acento(character varying)
    OWNER TO postgres;


-- Valida CNPJ
CREATE OR REPLACE FUNCTION public.fc_valida_cnpj(
	p_cnpj character varying,
	p_fg_permite_nulo boolean DEFAULT false)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    
    v_cnpj_invalidos character varying[10] 
    default array['00000000000000', '11111111111111',
                  '22222222222222', '33333333333333',
                  '44444444444444', '55555555555555',
                  '66666666666666', '77777777777777',
                  '88888888888888', '99999999999999'];
                  
    v_cnpj_quebrado smallint[];
    
    c_posicao_dv1 constant smallint default 13;
    v_arranjo_dv1 smallint[12] default array[5,4,3,2,9,8,7,6,5,4,3,2];
    v_soma_dv1 smallint default 0;
    v_resto_dv1 double precision default 0;
    
    c_posicao_dv2 constant smallint default 14;
    v_arranjo_dv2 smallint[13] default array[6,5,4,3,2,9,8,7,6,5,4,3,2];
    v_soma_dv2 smallint default 0;
    v_resto_dv2 double precision default 0;
    
begin
    
    if p_fg_permite_nulo and nullif(p_cnpj, '') is null then
        return true;
    end if;
    
    if (not (p_cnpj ~* '^([0-9]{14})$' or 
             p_cnpj ~* '^([0-9]{2}\.[0-9]{3}\.[0-9]{3}\/[0-9]{4}\-[0-9]{2})$')) or
        p_cnpj = any (v_cnpj_invalidos) or
        p_cnpj is null
    then
        return false;    
    end if;
    
    v_cnpj_quebrado := regexp_split_to_array(
      regexp_replace(p_cnpj, '[^0-9]', '', 'g'), '');
        
    -- Realiza o calculo do primeiro digito
    for t in 1..12 loop
        v_soma_dv1 := v_soma_dv1 + 
      (v_cnpj_quebrado[t] * v_arranjo_dv1[t]);
    end loop;
    v_resto_dv1 := ((10 * v_soma_dv1) % 11) % 10;
       
    if (v_resto_dv1 != v_cnpj_quebrado[13]) 
    then
        return false;
    end if;
    
    -- Realiza o calculo do segundo digito    
    for t in 1..13 loop
        v_soma_dv2 := v_soma_dv2 + 
      (v_cnpj_quebrado[t] * v_arranjo_dv2[t]);
    end loop;
    v_resto_dv2 := ((10 * v_soma_dv2) % 11) % 10;
    
    return (v_resto_dv2 = v_cnpj_quebrado[c_posicao_dv2]);    
    
end;
$BODY$;

ALTER FUNCTION public.fc_valida_cnpj(character varying, boolean)
    OWNER TO postgres;
	


-- Valida CPF

CREATE OR REPLACE FUNCTION public.fc_valida_cpf(
	p_cpf character varying,
	p_valida_nulo boolean DEFAULT false)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    
    v_cpf_invalidos character varying[10] 
    default array['00000000000', '11111111111',
                  '22222222222', '33333333333',
                  '44444444444', '55555555555',
                  '66666666666', '77777777777',
                  '88888888888', '99999999999'];
                  
    v_cpf_quebrado smallint[];
    
    c_posicao_dv1 constant smallint default 10;    
    v_arranjo_dv1 smallint[9] default array[10,9,8,7,6,5,4,3,2];
    v_soma_dv1 smallint default 0;
    v_resto_dv1 double precision default 0;
    
    c_posicao_dv2 constant smallint default 11;
    v_arranjo_dv2 smallint[10] default array[11,10,9,8,7,6,5,4,3,2];
    v_soma_dv2 smallint default 0;
    v_resto_dv2 double precision default 0;
    
begin
    if p_valida_nulo and nullif(p_cpf, '') is null then
        return true;
    end if;
    if (not (p_cpf ~* '^([0-9]{11})$' or 
             p_cpf ~* '^([0-9]{3}\.[0-9]{3}\.[0-9]{3}\-[0-9]{2})$')
        ) or
        p_cpf = any (v_cpf_invalidos) or
        p_cpf is null
    then
        return false;    
    end if;
    
v_cpf_quebrado := regexp_split_to_array(
                    regexp_replace(p_cpf, '[^0-9]', '', 'g'), '');
    -------------------------------- Digito Verificador 1
    for t in 1..9 loop
        v_soma_dv1 := v_soma_dv1 + 
                     (v_cpf_quebrado[t] * v_arranjo_dv1[t]);
    end loop;
    v_resto_dv1 := ((10 * v_soma_dv1) % 11) % 10;
        
    if (v_resto_dv1 != v_cpf_quebrado[c_posicao_dv1]) 
    then
        return false;
    end if;
    
    -------------------------------- Digito Verificador 2
    for t in 1..10 loop
        v_soma_dv2 := v_soma_dv2 + 
                     (v_cpf_quebrado[t] * v_arranjo_dv2[t]);
    end loop;
    v_resto_dv2 := ((10 * v_soma_dv2) % 11) % 10;
    
    return (v_resto_dv2 = v_cpf_quebrado[c_posicao_dv2]);    
    
end;
$BODY$;

ALTER FUNCTION public.fc_valida_cpf(character varying, boolean)
    OWNER TO postgres;
	
	

CREATE DOMAIN public.dm_cnpj
    AS character varying(20);

ALTER DOMAIN public.dm_cnpj OWNER TO postgres;

ALTER DOMAIN public.dm_cnpj
    ADD CONSTRAINT dm_cnpj_check CHECK (fc_valida_cnpj(VALUE, true));
	
	
CREATE DOMAIN public.dm_cpf
    AS character varying(20);

ALTER DOMAIN public.dm_cpf OWNER TO postgres;

ALTER DOMAIN public.dm_cpf
    ADD CONSTRAINT dm_cpf_check CHECK (fc_valida_cpf(VALUE, true));

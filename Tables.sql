-- Tables

CREATE TABLE public.base_teste
(
	cpf dm_cpf COLLATE pg_catalog."default",
    private integer,
    incompleto integer,
    data_da_ultima_compra date,
    ticket_medio real,
    ticket_da_ultima_compra real,
    loja_mais_frequente dm_cnpj COLLATE pg_catalog."default",
    loja_da_ultima_compra dm_cnpj COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.base_teste
    OWNER to postgres;
	


CREATE TABLE public.base_teste_rejected
(
    cpf character varying(20) COLLATE pg_catalog."default",
    cpf_valido character varying(10) COLLATE pg_catalog."default",
    private integer,
    incompleto integer,
    data_da_ultima_compra character varying(255) COLLATE pg_catalog."default",
    ticket_medio character varying(255) COLLATE pg_catalog."default",
    ticket_da_ultima_compra character varying(255) COLLATE pg_catalog."default",
    loja_mais_frequente character varying(255) COLLATE pg_catalog."default",
    loja_mais_frequente_valido character varying(10) COLLATE pg_catalog."default",
    loja_da_ultima_compra character varying(255) COLLATE pg_catalog."default",
    loja_da_ultima_compra_valido character varying(10) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.base_teste_rejected
    OWNER to postgres;



CREATE TABLE public.fileuploaded
(
    dados text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.fileuploaded
    OWNER to postgres;

-- Trigger: trg_file_uploaded

-- DROP TRIGGER trg_file_uploaded ON public.fileuploaded;

CREATE TRIGGER trg_file_uploaded
    AFTER INSERT OR UPDATE 
    ON public.fileuploaded
    FOR EACH STATEMENT
    EXECUTE PROCEDURE public.fc_usa_trg_base_teste();
	


CREATE TABLE public.fileuploaded_backup
(
    dados text COLLATE pg_catalog."default",
    data_upload character varying(255) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.fileuploaded_backup
    OWNER to postgres;
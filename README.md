Pré-requisitos
Docker - v20.10.0

Navegador 
Google Chrome Version 87.0.4280.88 (Official Build) (64-bit)

# Instruções

Realizar o Download diretamente no site do github:

https://github.com/EBKopec/etl_base_teste.git

ou 

no terminal, em um diretório local de sua preferência, o comando abaixo:

git clone https://github.com/EBKopec/etl_base_teste.git


## Obs: Garantir que as portas: 5432 e 10000 não estão sendo usadas

Agora, sem sair do terminal, acessar o projeto etl_base_teste o seguinte comando:

	docker-compose up --build

e aguardar alguns minutos a aplicação ser instalada.



## Criando o banco de dados:
O banco de dados será instalado, mas sem objetos, por esta razão é necessario executar os dois arquivos sql em qualquer aplicação que faça conexão com o banco de dados Postgres.

## Executar os seguintes passos nesta sequência:
Para se conectar ao banco postgres:
	host: localhost
	port: 5432
	DB_name: nw_base_teste
	Password: nw2020

Depois de conectado, executar os arquivos:
- Functions_triggers.sql (no qual possui comandos DDL para criação de alguns objetos);
- Tables.sql (para a criação das tables).

Logo após a execução dos arquivos acima.

## Utilizar o navegador Google Chrome com a URL abaixo:
    localhost:10000

Aparecerá a mensagem de boas vindas.
Isso garante que o serviço está funcionando.

Logo após isso, acessar a URL:
localhost:10000/upload

Onde irá mostrar a página que realizar o uploado do arquivo base_teste.txt.
Após a execução, caso venha ter sido executado todos os passos anteriores sem problemas, aparecerá a mensagem: "Arquivo base_teste.txt Carregado com Sucesso!"

Com isso o arquivo está armazenado no servidor e as informações persistidas no banco de dados nw_base_teste.

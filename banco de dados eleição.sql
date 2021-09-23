
/* 

TRABALHO REALIZADO UTILIZANDO MySQL Workbench 8.0

SISTEMA OPERACIONAL UTILIZADO Windows 10 Home Single Language versão 1803 - 64 bits


TRABALHO FEITO PELOS ALUNOS:

* JOÃO PEDRO BALBINO
* JOÃO VICTOR AGUIAR NAVES
* WANDER DO NASCIMENTO FERREIRA
* WILTON JOSÉ MIGUEL VELOZO

OBS: 1- É NECESSÁRIO QUE EXECUTE POR PARTES O BANCO DE DADOS PARA QUE NÃO HAJA ERROS
	 2- CONTÉM TABELA logEleicao e STORED PROCEDURE sp_libera_eleicao  USADOS PARA O TRABALHO DE C#
     É PRECISO QUE EXECUTE A TABELA E STORED PROCEDURE PARA QUE A TRIGGER atualizaLog SEJA EXECUTADA CORRETAMENTE
     3- OS COMENTÁRIOS ABAIXO TEM COMO OBJETIVO COMPLEMENTAR TODO O PROCESSO DE DESENVOLVIMENTO DESTE BANCO DE DADOS,
     QUALQUER DÚVIDA ESTAMOS A DISPOSIÇÃO.

*/


/*------------------------CRIA O ESQUEMA DO BANCO DE DADOS-------------------------*/

create schema bdEleicao;


/*------------------------USA O ESQUEMA DO BANCO DE DADOS--------------------------*/

use bdEleicao;

/*------------------------CRIA A TABELA ELEIÇÃO------------------------------------*/

/* NESTA TABELA A COLUNA QUANTIDADE DE CANDIDATOS E VOTOS VÁLIDOS ESTÃO DECLARADOS APENAS
COMO INT, POIS O STORED PROCEDURE CADASTRO DE ELEIÇÃO PASSARÁ COMO PADRÃO O VALOR DE 0*/

create table bdEleicao.tblEleicao(

codEleicao int not null,

tituloEleicao varchar(120) not null,

dataCadastramento date not null,

dataEleicao date not null,

paisEleicao varchar(120) not null,

statusEleicao varchar(9) not null,

quantidadeCandidatos int,

votosValidos int,

primary key(codEleicao)

);

/*------------------------CRIA A TABELA CANDIDATO-----------------------------------*/

/*NA TABELA DE CANDIDATO TEMOS CHAVE PRIMÁRIA E UNIQUE, POIS NAO PODEMOS PERMITIR 
DOIS PARTIDOS COM MESMO NÚMERO PARA UMA MESMA ELEIÇÃO, A COLUNA DE VOTOS DO CANDIDATO É APENAS INT */

create table bdEleicao.tblCandidato(

cpfCandidato char(11)  not null,

nomeCandidato varchar (120) not null,

nomeAbreviado varchar (60) not null,

dataNascimento date not null,

codigoEleicao int not null,

numeroDoPartido int not null,

nomeDoPartido varchar (256) not null,

votoDoCandidato int,

primary key (cpfCandidato),

unique (numeroDoPartido),

foreign key (codigoEleicao) references bdEleicao.tblEleicao(codEleicao)

);

/*------------------------CRIA A TABELA DE RESULTADOS--------------------------------*/

/*ESTA TABELA RECEBERÁ OS VOTOS BRANCOS E NULOS, ALÉM DE OUTRAS COLUNAS ESPECIFICADAS ABAIXO, FICOU O NÚMERO ID COMO CHAVE PRIMÁRIA*/

create table bdEleicao.tblResultado(

id int auto_increment,

numeroPartido int not null,

codigoEleicao int not null,

dtaEleicao datetime not null,

votosBrancos int not null,

votosNulos int not null,

primary key(id)

);


/*------------------CRIA A TABELA DE LOG USADO NO TRABALHO C#-------------------------*/

/*USADO PARA LOG DE ELEIÇÃO PARA O TRABALHO DE C#,  A FUNÇÃO PRINCIPAL É PERMITIR 
ANALISAR SE A ELEIÇÃO EXISTE E EXISTINDO ENTÃO PODERÁ CHAMAR O FORMULÁRIO DE VOTAÇÃO*/

create table bdEleicao.logEleicao(


logCode int,

logData datetime,

logStatus varchar (50),

primary key(logCode)

);

/*--------------------CRIA STORED PROCEDURE SALVAR ELEIÇÃO----------------------------*/

/* NA STORED PROCEDURE TEMOS OS PARAMETROS RESPONSÁVEIS POR RECEBER DO 'CALL' OS DADOS INFORMADOS, A DECLARAÇÃO
DE CADA ATRIBUTO ABAIXO PRECISA RESPEITAR OS ATRIBUTOS DA TABELA (NESTE CASO ELEIÇÃO), PORÉM NAO PODEMOS
COLOCAR O NOT NULL, SE VOCE COLOCAR APRESENTARÁ ERRO, O DELIMITER É RESPONSÁVEL POR PERMITIR QUE SEJAM EXCUTADAS DENTRO DE UM 
'ESPAÇO' TODAS 'AS CONDIÇÕES CRIADAS'*/

delimiter $$

create  procedure sp_eleicao_save (

pcodEleicao int,

ptituloEleicao varchar(120),

pdataCadastramento date,

pdataEleicao date,

ppaisEleicao varchar(120),

pstatusEleicao varchar(9)

)

/* VAMOS IMAGINAR QUE NO MOMENTO ESTAMOS CADASTRANDO UMA ELEIÇÃO, HÁ ALGUMAS INFORMAÇÕES QUE 
PRECISAMOS LEVAR EM CONTA: 1°- EXISTE O CÓDIGO NA TABELA? 

OBSERVANDO ESTA QUESTÃO COMECEMOS AVALIANDO O SEGUINTE CRITÉRIO:

 NÃO EXISTE O CÓDIGO? SE A RESPOSTA FOR SIM
ENTAO: INSERE TODOS OS DADOS VINDOS DO 'CALL', EXCETO QUANTIDADE DE CANDIDATOS QUE RECEBE POR PADRÃO 0, AFINAL ISSO É APENAS UM
CADASTRAMENTO DE ELEIÇÃO E NÃO CANDIDATO. VOTOS VÁLIDOS TAMBÉM É PASSADO COMO ZERO, AFINAL NÃO ESTAMOS VOTANDO AQUI.

CONTUDO PODEMOS JÁ TER ESSA ELEIÇÃO CADASTRADA NO BANCO DE DADOS, ENTÃO NÃO ENTRAMOS NO PRIMEIRO IF
VAMOS PARA O ELSE, E NELE ENTÃO TEMOS UM IF QUE ANALISA O SEGUINTE:

 NA MINHA TABELA DE ELEIÇÃO EU TENHO RETORNO SOBRE OS STATUS COM VALOR 'ANDAMENTO'?
NESTA PARTE A TABELA RETORNARÁ VÁRIAS LINHAS QUE PORVENTURA TENHAM O STATUS DE ANDAMENTO, MAS ISSO SERÁ TRATADO LOGO ABAIXO,
O PRIMEIRO IF COMPARA O ATRIBUTO DE PARAMETRO COM A PALAVRA 'ANDAMENTO', ISSO NOS PERMITE EXECUTARMOS UMA AÇÃO,
SE O IF RETORNAR VERDADEIRO, ENTÃO PODEREMOS ATUALIZAR QUALQUER INFORMAÇÃO NUMA LINHA EM RELAÇÃO AO CODIGO DA ELEIÇÃO, POR ISSO
DA CLAUSULA WHERE, ESTA CLAUSULA PERMITIRÁ QUE EXECUTEMOS APENAS O UPDATE EM RELAÇAO AO CÓDIGO QUE PASSAMOS POR PARAMETRO, DESCARTANDO 
QUALQUER ALTERAÇÃO INDESEJADA DE OUTRAS LINHAS, POR FIM TEMOS UM ELSE QUE SÓ SERÁ EXECUTADA SE O RETORNO DO STATUS FOR DIFERENTE 
DE ANDAMENTO

FINALIZANDO TEMOS O ROLLBACK QUE PERMITE NAO EXECUTAR ALTERAÇÃO PRESERVANDO A TABELA OU COMMIT QUE CONFIRMA ALTERAÇÃO*/
begin

declare statusCompare varchar(9);

start transaction;

if not exists(select codEleicao from bdEleicao.tblEleicao where pcodEleicao = codEleicao) then

	insert into bdEleicao.tblEleicao values (pcodEleicao, ptituloEleicao, pdataCadastramento, pdataEleicao, ppaisEleicao, pstatusEleicao,0,0);

 
else 

	if exists( select statusEleicao from bdEleicao.tblEleicao where pstatusEleicao = statusEleicao) then

		if(pstatusEleicao = 'andamento') then
        
			update bdEleicao.tblEleicao 
        
			set codEleicao = pcodeEleicao, tituloEleicao = ptituloEleicao, dataCadastramento = pdataCadastramento, dataEleicao = pdataEleicao, 
        
			paisEleicao = ppaisEleicao, statusEleicao = 'andamento' -- NAO SE ATUALIZA QUANTIDADE DE CANDIDATOS AQUI E NEM VOTOS VALIDOS
            
			where pcodEleicao = codEleicao;        
 
		else -- VOCE NAO PODE ATUALIZAR UMA ELEIÇÃO QUE NAO ESTA EM ANDAMENTO
			select 'Não é possível alterar os dados' as Erro_de_Alteracao;   
            rollback;
		
		end if;
	end if;
end if;

	
commit;

select 'Dados inseridos com sucesso!' as Cadastro_com_sucesso;


end $$

delimiter ;

/*--------------------CRIA STORED PROCEDURE SALVAR CANDIDATO---------------------------*/

delimiter $$

create procedure sp_candidato_save(

pcpfCandidato char(11),

pnomeCandidato varchar (120),

pnomeAbreviado varchar (60),

pdataNascimento date,

pcodigoEleicao int,

pnumeroDoPartido int,

pnomeDoPartido varchar (256)



)

/* PARTIMOS AGORA PARA O CADASTRAMENTO DO CANDIDATO, PRIMEIRAMENTE DEVEMOS OBSERVAR O ÍTEM
MAIS IMPORTANTE, O CÓDIGO DA ELEIÇÃO, OU SEJA, NÃO PODEMOS CADASTRAR UM CANDIDATO EM UMA ELEIÇÃO
QUE NÃO EXISTA, POR ISSO COMECEMOS ANALISANDO DA SEGUINTE FORMA:

PRIMERO IF PERGUNTA SE REALMENTE EXISTE O CÓDIGO QUE PASSAMOS POR PARAMETRO NA TABELA DE ELEIÇÃO,
VAMOS SUPOR QUE REALMENTE EXISTA ESTE CÓDIGO:

ENTÃO CAÍMOS NO SEGUNDO IF, ESTE IF VERIFICA SE O CPF DO CANDIDATO PASSADO POR PARAMETRO
NAO EXISTE NA TABELA DE CANDIDATOS, SE RETORNAR VERDADEIRO, ENTÃO TEMOS UM INSERT NESTA TABELA.

APÓS A INSERÇÃO ENTÃO REALIZAREMOS A ATUALIZAÇÃO DE QUANTIDADE DE CANDIDATOS PARA AQUELA ELEIÇÃO NA TABELA DE ELEIÇAO.

PORÉM PODEMOS JÁ TER O CANDIDATO CADASTRADO NESTA TABELA, ENTÃO O ELSE APENAS EXECUTARÁ O UPDATE DOS DADOS.

POR FIM TEMOS O ÚLTIMO ELSE, SE O CODIGO NÃO EXISTIR NA TABELA DE ELEIÇAO ENTAO ESTE ELSE
IRA MOSTRAR UMA MENSAGEM DE ERRO E DESFAZER QUALQUER ALTERAÇÃO, PERMANECENDO A TABELA CONCISA

CASO TUDO OCORRA BEM PARA INSERT OU UPDATE ENTÃO EXECUTEMOS O COMMIT*/

begin


declare cpfCompare int;


start transaction;

if  exists (select codEleicao from bdEleicao.tblEleicao where codEleicao  = pcodigoEleicao)then	
    
	if not exists (select  cpfCandidato from bdEleicao.tblCandidato where cpfCandidato  = pcpfCandidato) then
			
            
            insert into bdEleicao.tblCandidato values (pcpfCandidato, pnomeCandidato, pnomeAbreviado, pdataNascimento,
            
				pcodigoEleicao, pnumeroDoPartido, pnomeDoPartido, 0);
                
			update  bdEleicao.tblEleicao
            set quantidadeCandidatos = quantidadeCandidatos + 1
            where codEleicao = pcodigoEleicao;
                
	else 				
		
		
		update bdEleicao.tblCandidato 
            
		set cpfCandidato = pcpfCandidato, nomeCandidato = pnomeCandidato, nomeAbreviado = pnomeAbreviado, dataNascimento = pdataNascimento,
	
			codigoEleicao = pcodigoEleicao, numeroDoPartido = pnumeroDoPartido, nomeDoPartido = pnomeDoPartido
                
		where cpfCandidato = pcpfCandidato;        
		
	end if;        
	
    
else	
    
    select 'Código não encontrado no banco de dados!' as Erro_cadastro_Candidato;
	rollback;	

end if;    
		
commit;

end $$


delimiter ;

/*--------------------CRIA STORED PROCEDURE DE LIBERAÇÃO PARA O TRABALHO DE C#----------*/

delimiter $$


create procedure sp_libera_eleicao(

	in pcodigo int
    
)

/* AQUI TEMOS UMA STORED PROCEDURE USADO PARA O TRABALHO DE C#, ELE É RESPONSÁVEL POR
PERMITIR OU NÃO QUE HAJA ACESSO AO FORMULÁRIO DE VOTAÇÃO

INICIAMOS DECLARANDO DUAS VARIAVEIS ELAS SERÃO RESPONSAVEIS POR GUARDAR CODIGO VINDO
DO PARAMETRO E STATUS DE 'ACESSO LIBERADO' DECLARADO NO STORED PROCEDURE

PRIMEIRO IF VERIFICA SE EXISTE O CÓDIGO NA TABELA DE ELEIÇÃO, PARA ESTE CASO NAO USAMOS COMMIT  E NEM
ROLLBACK, AFINAL DE QUALQUER FORMA ESTE PROCEDURE SALVARÁ NA TABELA DE LOG INFORMAÇÃO SOBRE A ELEIÇÃO

ENTÃO SE EXISTE O CODIGO PODEMOS USAR A VARIAVEL DECLARADA PARA RECEBER O CODIGO DE PARAMETRO,
USAMOS O LAST_INSERT_ID, GUARDAMOS ESTE CODIGO PARA FUTURO USO NO PROCEDURE

PRÓXIMO IF VERIFICA QUANTO AOS STATUS DA ELEIÇÃO PASSADA POR PARAMETRO SE FOR 'ANDAMENTO' ENTÃO ... 

... CAÍMOS NO PRÓXIMO IF, ELE VERIFICA SE NÃO EXISTE UM LOGCODE
(TAL LOGCODE USADO NA TABELA DE LOGELEICAO É CHAVE PRIMÁRIA), PORTANTO NÃO HAVERÁ MAIS DO QUE A PRÓPRIA LINHA DO LOGCODE
NESTA TABELA 

SE NÃO EXISTIR ENTÃO SETAMOS STATUSACESSO COM 'ACESSO LIBERADO', LOGO APÓS REALIZAMOS O INSERT SEGUNDO:

CODIGOATUAL DECLARADO ACIMA, NOW() [NOW INSERE A DATA DE HOJE E HORÁRIO, COMO SÓ PODEMOS LIBERAR UMA ELEIÇÃO NA DATA EM QUE ELE OCORRERÁ,
ENTÃO PODEMOS UTILIZAR A PALAVRA RESERVADA ACIMA] E POR FIM O STATUSACESSO

PORÉM PODE SER QUE JÁ EXISTA ESTE LOGCODE, SE EXISTIR VAMOS APENAS ATUALIZAR SUAS INFORMAÇÕES
SEGUINDO A CLAUSULA WHERE

TEMOS UM ELSEIF QUE VERIFICA SE O STATUS DA ELEIÇÃO FOR DIFERENTE DE ANDAMENTO, SE FOR O STATUS NA TABELA LOG ELEIÇÃO PARA AQUELA ELEIÇÃO
SERÁ 'ACESSO NEGADO' MESMO HAVENDO OU NÃO O LOGCODE

 CONTUDO PODEMOS NÃO TER O CODIGO DA ELEIÇÃO PASSADO POR PARAMETRO NA TABELA DE ELEIÇÃO, NESTE CASO
 NÃO PODEMOS PERMITIR QUE O FORMULÁRIO DE VOTAÇÃO SEJA ABERTA [TRABALHO C#], SE EXECUTARMOS
 O CALL PELO BD, VEREMOS A MENSAGEM DE 'ACESSO NEGADO' SALVO NA TABELA DE LOG*/

Begin	
	
    declare codigoAtual int;
    declare statusAcesso varchar (50);
    
    start transaction; 
 
	 if exists (select codEleicao  from bdEleicao.tblEleicao where codEleicao=pcodigo) then
    
		set codigoAtual  = last_insert_id(pcodigo);
        
			if exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao=pcodigo and  statusEleicao = 'andamento') then

        
				if not exists ( select logCode from bdEleicao.logEleicao where logCode = codigoAtual) then
			
					set statusAcesso = 'acesso liberado';
            
					insert into bdEleicao.logEleicao values (codigoAtual,now(),statusAcesso);
					
                    
				elseif exists(select logCode from bdEleicao.logEleicao where logCode = codigoAtual) then                
                
					update bdEleicao.logEleicao
					set logStatus = 'acesso liberado', logData = now()
					where logCode = codigoAtual;
				
				end if;
 
			elseif exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao=pcodigo and  statusEleicao <> 'andamento') then
	
				
				if not exists ( select logCode from bdEleicao.logEleicao where logCode = codigoAtual) then
			
					set statusAcesso = 'acesso negado';
            
						insert into bdEleicao.logEleicao values (codigoAtual,now(),statusAcesso);
					
                    
				elseif exists(select logCode from bdEleicao.logEleicao where logCode = codigoAtual) then                
                
					update bdEleicao.logEleicao
					set logStatus = 'acesso negado', logData = now()
					where logCode = codigoAtual;	
        
    
				end if;
           
           end if	;
           
	 elseif not exists (select codEleicao,statusEleicao from bdEleicao.tblEleicao where codEleicao=pcodigo) then
		
        insert into bdEleicao.logEleicao values(pcodigo,now(), 'acesso negado');
        
	
end if;
        

end $$;

delimiter ;



/*--------------------CRIA STORED PROCEDURE DE VOTAÇÃO-----------------------------------*/

delimiter $$

create procedure sp_voto(

pPartido int,
pCodigo int


)

/* PRIMEIRO IF VERIFICA SE REALMENTE EXISTE UM CODIGO DA ELEIÇÃO CADASTRADA NA TABELA DE 
ELEIÇÃO.

TEMOS OUTRO IF QUE VERIFICA SE A ELEIÇÃO ESTÁ EM ADAMENTO

DEPOIS TEMOS O PRÓXIMO IF QUE VERIFICA SE O NUMERO DO PARTIDO EXISTE NA TABELA DE CANDIDATO BEM COMO O CODIGO DA ELEIÇÃO DA REFERIDA TABELA
 ENTÃO POR FIM EXECUTA-SE O UPDATE DA TABELA DE CANDIDATO CONTANDO COMO VOTO DO CANDIDATO
SEGUNDO A CLAUSULA WHERE.

LOGO APÓS FAZEMOS UM UPDATE NA TABELA DE ELEIÇÃO, PARA CONTAR OS VOTOS VÁLIDOS PARA OS PARTIDOS 
QUE ESTÃO CADASTRADOS NA TABELA DE CANDIDATOS.

PORÉM PODE OCORRER DE NÃO EXISTIR O  NÚMERO DO PARTIDO EM RELAÇAO AO QUE PASSAMOS POR PARAMETRO
LEVANDO EM CONSIDERAÇÃO O CODIGO DA ELEIÇÃO, SE NAO ENCONTRAMOS NA TABELA DE CANDIDATOS, O QUE NOS RESTA É PROCURAR
NA TABELA DE RESULTADO SE ENCONTRAMOS ESSE PARTIDO LÁ E O REFERIDO CÓDIGO [LEMBRANDO QUE TABELA DE RESULTADO SÓ
GUARDA VOTOS BRANCOS, NULOS ENTRE OUTROS]. SE NAO EXISTIR O CODIGO DA ELEIÇÃO E O NUMERO DO
PARTIDO NESTA TABELA, ENTAO FAREMOS UM INSERT COM:

NULL, NUMERO DO PARTIDO, NUMERO DO CÓDGIGO, NOW [ DATA E HORA ATUAL], 0 E 1 [VOTO NULOS]

CONTUDO PODE SER QUE TENHAMOS NA TABELA DE RESULTADO O COGIGO E NUMERO DO PARTIDO
ENTÃO EXECUTEMOS APENAS O UPDATE ACRESCENTANDO VOTO NULO, NESTE CASO NÃO ACRESCENTA 
VOTO VALIDO NA TABELA DE ELEIÇÃO, POIS ESTAMOS APENAS CONTANDO TOTAL DE VOTOS NULOS PARA AQUELE 
NUMERO  DE PARTIDO NO QUAL NAO EXISTE NA TABELA DE CANDIDATOS.

TEMOS O ELSEIF QUE VERIFICA QUANTO AO STATUS, SE FOR DIFERENTE DE 'ANDAMENTO' ENTÃO NÃO 
É POSSIVEL REALIZAR A VOTAÇÃO


E POR FIM TEM-SE O ULTIMO ELSE QUE SE O CODIGO DA ELEIÇÃO PASSADO POR PARAMETRO
NAO EXISTIR NA TABELA DE ELEIÇÃO, ENTÃO NÃO SERÁ POSSÍVEL ADICIONAR UM VOTO.*/

Begin
  

	start transaction;   
  	  
if exists(select codEleicao from bdEleicao.tblEleicao where codEleicao = pCodigo) then
    
     if exists(select codEleicao from bdEleicao.tblEleicao where codEleicao = pCodigo and statusEleicao = 'andamento') then
    
		if exists( select numeroDoPartido from bdEleicao.tblCandidato where numeroDoPartido = pPartido and codigoEleicao = pCodigo ) then
			            

			update bdEleicao.tblCandidato
			set votoDoCandidato = votoDoCandidato + 1
			where numeroDoPartido = pPartido and codigoEleicao = pCodigo;
			
            update  bdEleicao.tblEleicao
            set votosValidos = votosValidos + 1
            where codEleicao = pCodigo;
			
            
    
		elseif not exists(select numeroDoPartido, codigoEleicao from bdEleicao.tblCandidato where numeroDoPartido  = pPartido and codigoEleicao = pCodigo) then        
			
			if not  exists(select numeroPartido  from bdEleicao.tblResultado where codigoEleicao = pCodigo and numeroPartido = pPartido) then
		        
                     
				 insert into	 bdEleicao.tblresultado values( null, pPartido, pCodigo, now(), 0, 1);
                
           
			elseif  exists(select numeroPartido  from bdEleicao.tblResultado where codigoEleicao = pCodigo and numeroPartido = pPartido) then
				
                update bdEleicao.tblResultado
                set votosNulos = votosNulos + 1
                where codigoEleicao = pCodigo and numeroPartido = pPartido;
                
			
			end if;
            
		end if;
        
     elseif exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao=pcodigo and  statusEleicao <> 'andamento') then

    
		select 'Não é possível realizar a votação!' as erro;
        
	
		end if;	
        
	else
    
		select 'Eleição não existente' as Erro_de_votacao;
       
	end if;  

end $$;


delimiter ;

/*-------------------CRIA STORED PROCEDURE PARA VOTOS EM BRANCO --------------------------*/

delimiter $$

create procedure sp_voto_branco(

pPartido int,
pCodigo int

)

/* COMO PADRÃO VERIFICAMOS SE EXISTE DA FATO A ELEIÇÃO PASSADO POR PARAMETRO


VERIFICAMOS QUANTOS AO STATUS DA ELEIÇÃO

LOGO APÓS VERIFICAMOS SE JÁ EXISTE NA TABELA DE RESULTADO O CODIGO E NUMERO DE PARTIDO, POR PADRÃO DEFINIMOS COMO 
NUMERO DO PARTIDO O VALOR -1 [ TRABALHO DE C# TAMBÉM], SE JÁ EXISTE ENTÃO EXECUTEMOS O UPDATE PARA
VOTOS BRANCOS.

CASO NAO EXISTA NA TABELA DE RESULTADO O VALOR -1, ENTÃO ACRESCENTAMOS NULL, O RESPECTIVO VALOR, O CODIGO
DA EELEIÇÃO, DATA E HORA ATUAL E O VOTO BRANCO.

SE O STATUS DA ELEIÇÃO PASSADO POR PARAMETRO FOR DIFERENTE DE 'ANDAMENTO', ENTÃO NÃO SERÁ POSSÍVEL
REALIZAR A VOTAÇÃO.

POR FIM SE DE TUDO NAO EXISTIR O CODIGO DE ELEIÇÃO PASSADO POR PARAMETRO, ENTÃO
NÃO SERÁ POSSÍVEL VOTAR*/

begin


	start transaction;
    

if exists(select codEleicao from bdEleicao.tblEleicao where codEleicao = pCodigo) then

	if exists(select codEleicao from bdEleicao.tblEleicao where codEleicao = pCodigo and statusEleicao = 'andamento') then
    
		if exists(select codigoEleicao, numeroPartido from bdEleicao.tblResultado where codigoEleicao = pCodigo and numeroPartido = pPartido)then

				update bdEleicao.tblResultado
                set votosBrancos = votosBrancos + 1
                where numeroPartido = pPartido and codigoEleicao = pCodigo;
		
        
		elseif not exists(select codigoEleicao  from bdEleicao.tblResultado where codigoEleicao = pCodigo and numeroPartido = pPartido) then
		        				                
			insert into	 bdEleicao.tblResultado values(null,pPartido, pCodigo, now(), 1, 0);
			
		end if;
        
	elseif exists(select codEleicao from bdEleicao.tblEleicao where codEleicao = pCodigo and statusEleicao <> 'andamento') then

		select 'Não é possível realizar a votação' as erro;
   
   end if;
   
else
    
    
	select 'Eleição não existente' as Erro_de_votacao;
    rollback;
    
end if;  
    
end$$;


delimiter ;


/*--------------------CRIA A STORED PROCEDURE CONTABILIZA VOTOS-----------------------------*/





delimiter $$

create procedure spVencedor(


pCodEleicao int

)

/* PRIMEIRAMENTE VERIFICAMOS SE EXISTE A ELEIÇÃO PASSADO POR PARAMETRO NA TABELA DE ELEIÇÃO, CASO SIM ENTÃO...

VERIFICAMOS SE ESTA ELEIÇÃO TEM SEU STATUS COMO 'ENCERRADA', SE SIM ENTÃO...

REALIZAMOS O SELECT TRAZENDO: NOME DO CANDIDATO, NUMERO DO PARTIDO, QUANTIDADE DE VOTOS, SE É VENCEDOR
DA TABELA DE CANDIDATO ENQUANDO O CODIGOELEICAO FOR IGUAL AO QUE PASSOU POR PARAMETRO E
VOTODOCANDIDATO FOR O MAIOR (MAX) NA TABELA DE CANDIDATO ENQUANTO O CODIGO DA ELEIÇÃO NA TABELA DE CANDIDATO
FOR DE FATO IGUAL AO CODIGO PASSADO POR PARAMETRO, AGRUPANDO PELO CODIGO DA ELEIÇÃO E TENDO COMO MÁXIMO O VOTODOCANDIDATO.

TEMOS ELSEIF QUE VERIFICA SE O STATUS DA ELEIÇÃO ESTÁ EM ANDAMENTO, SE SIM NÃO É POSSÍVEL CONTABILIZAR OS VOTOS

TEMOS OUTRO ELSEIF QUE VERIFICA SE O STATUS ESTÁ CANCELADA, SE SIM TAMBÉM NÃO É POSSÍVEL CONTABILIZAR OS VOTOS

E POR FIM SE O CÓDIGO DA ELEIÇÃO NAO EXISTIR NA TABELA DE ELEIÇÃO, ENTÃO EXIBIMOS UMA MENSAGEM DZENDO QUE
NÃO FOI POSSÍVEL ENCONTRAR A ELEIÇÃO*/

begin	


    declare pvotosValidos int;
	declare nome varchar(256);    
    declare vt int;
    
   
if exists (select codEleicao from bdEleicao.tblEleicao where codEleicao = pCodEleicao) then

    if exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pCodEleicao and statusEleicao = 'encerrada') then   
    
		select C.nomeCandidato, numeroDoPartido, votoDoCandidato, '1° Lugar' as vencedor  from bdEleicao.tblCandidato C
		where C.codigoEleicao = pCodEleicao and votoDoCandidato = (select max(votoDoCandidato) from bdEleicao.tblCandidato
		where codigoEleicao = pCodEleicao)
		group by C.codigoEleicao
		having max(votoDoCandidato);
        
        
    
	elseif exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pCodEleicao and statusEleicao  = 'andamento') then
   
		select 'Esta eleição não foi encerrada por isso não será possível contabilizar os votos' as erro;
        
			elseif exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pCodEleicao and statusEleicao = 'cancelada') then
    
				select 'Esta eleição foi cancelada não sendo possível contabilizar os seus votos' as erro;
        
   end if;
		
else

	select 'Não foi possível encontrar esta eleição no banco de dados!' as erro;

end if;

    


end $$;


delimiter ;

/*-----------------------CRIA A STORED PROCEDURE ENCERRA ELEIÇÃO-----------------------------*/


delimiter $$

create procedure encerraEleicao(

pcodEleicao int


)

/* OBJETIVO DESTA PROCEDURE É ENCERRAR UMA ELEIÇÃO QUE EXISTA É CLARO, TRATAMOS QUANTO AO CASO DELA ESTAR
JÁ ENCERRADA OU CANCELADA, EXIBINDO AS MENSAGENS (LOGO ABAIXO PODERA VÊ-LAS)

E POR FIM SE NÃO EXISTE A ELEIÇÃO PASSADA POR PARAMETRO NA TABELA DE ELEIÇÃO, ENTÃO
EXIBIMOS UMA MENSAGEM DIZENDO QUE A ELEIÇÃO NÃO EXISTE.*/

begin

	
    if exists (select codEleicao from bdEleicao.tblEleicao where codEleicao =  pcodEleicao) then
    
		if exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pcodEleicao and statusEleicao = 'andamento') then
        
			update bdEleicao.tblEleicao
            set statusEleicao = 'encerrada'
            where codEleicao = pcodEleicao;
            
		elseif exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pcodEleicao and statusEleicao <> 'andamento') then
        
			select 'Não é possível encerrar uma eleição encerrada ou cancelada' as erro;
            
		end if;
        
	else
    
		select 'Eleição não existe' as erro;
	
    end if;

end $$

delimiter ;

/*-----------------------CRIA A STORED PROCEDURE CANCELA ELEIÇÃO-----------------------------*/


delimiter $$

create procedure cancelaEleicao(

pcodEleicao int


)

/* OBJETIVO DESTA PROCEDURE É CANCELAR UMA ELEIÇÃO QUE EXISTA É CLARO, TRATAMOS QUANTO AO CASO DELA ESTAR
JÁ ENCERRADA OU CANCELADA, EXIBINDO AS MENSAGENS (LOGO ABAIXO PODERA VÊ-LAS)

E POR FIM SE NÃO EXISTE A ELEIÇÃO PASSADA POR PARAMETRO NA TABELA DE ELEIÇÃO, ENTÃO
EXIBIMOS UMA MENSAGEM DIZENDO QUE A ELEIÇÃO NÃO EXISTE.*/

begin

	
    if exists (select codEleicao from bdEleicao.tblEleicao where codEleicao =  pcodEleicao) then
    
		if exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pcodEleicao and statusEleicao = 'andamento') then
        
			update bdEleicao.tblEleicao
            set statusEleicao = 'cancelada'
            where codEleicao = pcodEleicao;
            
		elseif exists (select statusEleicao from bdEleicao.tblEleicao where codEleicao = pcodEleicao and statusEleicao <> 'andamento') then
        
			select 'Não é possível encerrar uma eleição encerrada ou cancelada' as erro;
            
		end if;
        
	else
    
		select 'Eleição não existe' as erro;
	
    end if;

end $$

delimiter ;

/*---------------------------CRIA A STORED PROCEDURE ATUALIZA LOG------------------------------*/

/* TRIGGER ABAIXO ATUALIZA A TABELA DE LOGELEICAO ALTERANDO O STATUS DE 'ACESSO LIBERADO'
PARA 'ACESSO NEGADO' SEMPRE QUE ENCERRAMOS OU CANCELAMOS UMA DETERMINADA ELEIÇÃO*/
delimiter $$

create trigger  atualizaLog after update   on  bdEleicao.tblEleicao

for each row

begin

	if new.statusEleicao <> old.statusEleicao then
    
		update bdEleicao.logEleicao
		set logStatus = 'acesso negado', logData = now()
		where new.codEleicao = logCode;
    
    
	end if;


end$$

delimiter ;



/*----------------------------CADASTRANDO AS ELEIÇÕES--------------------------------------*/

call sp_eleicao_save(1,'Eleição MercoSul 2018','2018-11-16','2018-12-16','Brasil','andamento');
call sp_eleicao_save(2,'Eleição MercoSul 2018','2018-11-16','2018-12-16','Argentina','andamento');
call sp_eleicao_save(3,'Eleição MercoSul 2018','2018-11-16','2018-12-16','Paraguai','andamento');
call sp_eleicao_save(4,'Eleição MercoSul 2018','2018-11-16','2018-12-16','Uruguai','andamento');
call sp_eleicao_save(5,'Eleição MercoSul 2018','2018-11-16','2018-12-16','Chile','andamento');
call sp_eleicao_save(5,'Eleição MercoSul 2018','2018-11-16','2018-12-16','Chile','andamento'); -- APRESENTARÁ ERRO POIS JÁ FOI CADASTRADO -- 


/*----------------------------CADASTRANDO OS CANDIDATOS--------------------------------------*/ 

call sp_candidato_save ('11111111111','Antonio Carlos','ac','1975-11-19',1,10,'PL');
call sp_candidato_save ('11111111112','Paulo Cesar','pc','1977-05-01',1,20,'PV');
call sp_candidato_save ('11111111113','Ana Paula','ap','1966-07-15',2,30,'PT');
call sp_candidato_save ('11111111114','Lucas Pedro','lp','1976-02-08',2,55,'PS');
call sp_candidato_save ('11111111115','Carlos Henrique','ch','1950-06-13',3,50,'PC');
call sp_candidato_save ('11111111116','Laura Mariane','lm','1980-12-19',3,60,'PR');
call sp_candidato_save ('11111111117','Lindalva Souza','ls','1951-03-08',4,70,'PJ');
call sp_candidato_save ('11111111118','Everaldo Silva','es','1990-09-30',4,80,'PU');
call sp_candidato_save ('11111111119','Priscila Amorim','pa','1989-10-23',5,90,'PP');
call sp_candidato_save ('11111111120','Maria Eduarda','me','1945-11-01',5,100,'PX');
call sp_candidato_save ('11111111120','Maria Eduarda','me','1945-11-01',5,101,'PX'); -- EXECUTARIA UPDATE  POIS JÁ FOI CADASTRADO ANTERIORMENTE --


/*--------------LIBERANDO ACESSO PARA FORMULÁRIO DE VOTAÇÃO TRABALHO DE C#-------------------*/ 

call sp_libera_eleicao(1);  
call sp_libera_eleicao(2);  
call sp_libera_eleicao(3); 
call sp_libera_eleicao(8); -- APRESENTARÁ 'ACESSO NEGADO' POIS NÃO EXISTE ESTA ELEIÇÃO  
 


/*----------------------------VOTANDO NAS ELEIÇÕES-------------------------------------------*/ 

call sp_voto(20,1);
call sp_voto(10,1);
call sp_voto(30,2);
call sp_voto(40,2);
call sp_voto(50,3);
call sp_voto(50,3);
call sp_voto(60,3);
call sp_voto(60,3);
call sp_voto(60,3);
call sp_voto(100,5);
call sp_voto(77,9); -- EXIBIRÁ UM SELECT DIZENDO QUE NAO EXISTE ESTA ELEIÇÃO
call sp_voto(1,1);
call sp_voto(11,2);

/*--------------------------------VOTOS BRANCOS-----------------------------------------------*/ 


call sp_voto_branco(-1,1);
call sp_voto_branco(-1,1);
call sp_voto_branco(-1,2);
call sp_voto_branco(-1,1);
call sp_voto_branco(-1,3);
call sp_voto_branco(-1,77); -- EXIBIRÁ UM SELECT DIZENDO QUE NAO EXISTE ESTA ELEIÇÃO
call sp_voto_branco(-1,1);
call sp_voto_branco(-1,1);

/*------------------------------MOSTRA VENCEDOR DAS ELEIÇÕES----------------------------------*/ 


call spVencedor(1);
call spVencedor(2);
call spVencedor(3);
call spVencedor(8); -- EXIBIRÁ UM SELECT DIZENDO QUE NÃO EXISTE ESTA ELEIÇÃO

/*--------------------------------ENCERRA  OU CANCELA UMA ELEIÇÃO------------------------------*/ 


call cancelaEleicao(1);
call cancelaEleicao(2);
call encerraEleicao(3);


/*----------------------------SELECT PARA VERIFICAR AS TABELAS DO BANCO DE DADOS---------------*/ 


select * from bdEleicao.tblEleicao;

select * from bdEleicao.tblCandidato;

select *from bdEleicao.logEleicao;

select *from bdEleicao.tblResultado;





/*----------------------------------DROP TABLE-------------------------------------------*/

drop table bdEleicao.logEleicao;

drop table bdEleicao.tblResultado;

drop table bdEleicao.tblCandidato;

drop table bdEleicao.tblEleicao;

/*----------------------------------DROP PROCEDURE---------------------------------------*/

drop procedure sp_eleicao_save;

drop procedure sp_candidato_save;

drop procedure sp_libera_eleicao;

drop procedure sp_voto;

drop procedure sp_voto_branco;

drop procedure spVencedor;

drop procedure encerraEleicao;

drop procedure cancelaEleicao;

/*----------------------------------DROP TRIGGER---------------------------------------*/

drop trigger atualizaLog;

/*----------------------------------DROP SCHEMA---------------------------------------*/

drop schema bdEleicao;



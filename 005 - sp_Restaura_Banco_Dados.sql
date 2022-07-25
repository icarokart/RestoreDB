/*
-----------------------------------------------------------------------
Data de Criação: 25/07/2022
Nome do Objeto: sp_Restaura_Banco_Dados
Autor: Ícaro

Observações: execute um "SET DATEFORMAT DMY" antes de executar esse procedimento.
----------------------------------------------------------------------
*/

If Exists (Select 1 From Sysobjects Where Id = Object_Id('dbo.sp_Restaura_Banco_Dados'))
     Drop Procedure dbo.sp_Restaura_Banco_Dados
Go

Create Procedure dbo.sp_Restaura_Banco_Dados
(
        @SIGLA_CLIENTE VARCHAR(15)
	  , @TIPO_BANCO CHAR		--TIPO DO BANCO A SER RESTAURADO: D - DADOS // L - LOG // B - BINARIOS
	  , @NOME_MIDIA_BKP VARCHAR(50)
	  , @DATA_MIDIA_BACKUP VARCHAR(15)
	  , @OBSERVACOES VARCHAR(500)
) As
	Begin
		 Set NoCount On;
    
			 DECLARE
				@BD_CLIENTE VARCHAR(50)
			  , @DIR_MIDIA_BACKUP NVARCHAR(500)
			  , @NOME_ARQ_DADOS VARCHAR(50)
			  , @NOME_ARQ_LOG VARCHAR(50)
			  , @DIR_ARQ_DADOS NVARCHAR(500)
			  , @DIR_ARQ_LOG NVARCHAR(500)
			  , @DIR_BANCO NVARCHAR(500)
			  , @SQL_STATEMENT_RESTORE NVARCHAR(MAX)
			  , @SQL_STATEMENT_CREATE_DB NVARCHAR(MAX)
			  , @SQL_STATEMENT_CREATE_DB_CONT NVARCHAR(MAX)
			  , @ARQ_LOGICO_DATA VARCHAR(50)
			  , @ARQ_LOGICO_LOG VARCHAR(50)
			  , @BD_CLIENTE_SEM_COLCHETE VARCHAR(50)


			  --CARREGANDO OS PARAMETROS PARA A RESTAURAÇÃO
			SELECT @BD_CLIENTE = (SELECT QUOTENAME(NOME_BANCO) FROM PARAMETROS_RESTORE WHERE CLIENTE = @SIGLA_CLIENTE),
				   @BD_CLIENTE_SEM_COLCHETE = (SELECT NOME_BANCO FROM PARAMETROS_RESTORE WHERE CLIENTE = @SIGLA_CLIENTE),
				   @DIR_MIDIA_BACKUP = (SELECT DIRETORIO_MIDIA FROM PARAMETROS_RESTORE WHERE CLIENTE = @SIGLA_CLIENTE),
				   @NOME_ARQ_DADOS = (SELECT NOME_ARQ_DADOS FROM PARAMETROS_RESTORE WHERE CLIENTE = @SIGLA_CLIENTE),
				   @NOME_ARQ_LOG = (SELECT NOME_ARQ_LOG FROM PARAMETROS_RESTORE WHERE CLIENTE = @SIGLA_CLIENTE),
				   @DIR_BANCO =	(SELECT DIRETORIO_BANCO FROM PARAMETROS_RESTORE WHERE CLIENTE = @SIGLA_CLIENTE)
		   
			SET    @ARQ_LOGICO_DATA = ISNULL(
												(SELECT BF.logical_name
												 FROM MSDB.DBO.backupfile BF
													 JOIN MSDB.DBO.restorehistory RH
														 ON (BF.backup_set_id = RH.backup_set_id)
												 WHERE RH.destination_database_name = (SELECT NOME_BANCO 
																					   FROM PARAMETROS_RESTORE 
																					   WHERE CLIENTE = @SIGLA_CLIENTE)
											
													AND BF.file_type = 'D' 
													AND rh.restore_date = (SELECT MAX(rh2.RESTORE_DATE)
																		   FROM MSDB.DBO.restorehistory rh2
																			WHERE RH.destination_database_name = (SELECT NOME_BANCO 
																												   FROM PARAMETROS_RESTORE 
																												   WHERE CLIENTE = @SIGLA_CLIENTE))
											), @BD_CLIENTE_SEM_COLCHETE+'_Data')


			SET	   @ARQ_LOGICO_LOG = ISNULL (
											   (SELECT BF.logical_name
												FROM MSDB.DBO.backupfile BF
													JOIN MSDB.DBO.restorehistory RH
														ON (BF.backup_set_id = RH.backup_set_id)
												WHERE RH.destination_database_name = (SELECT NOME_BANCO 
								  													  FROM PARAMETROS_RESTORE 
																					  WHERE CLIENTE = @SIGLA_CLIENTE)
												AND BF.file_type = 'L'
												AND RH.restore_date = (SELECT MAX(rh2.RESTORE_DATE)
																		   FROM MSDB.DBO.restorehistory rh2
																			WHERE RH.destination_database_name = (SELECT NOME_BANCO 
																												   FROM PARAMETROS_RESTORE 
																												   WHERE CLIENTE = @SIGLA_CLIENTE))
																										   
											),@BD_CLIENTE_SEM_COLCHETE+'_Log')


			--CONCATENANDO OS DIRETÓRIOS
			SET @DIR_MIDIA_BACKUP = (SELECT @DIR_MIDIA_BACKUP+@NOME_MIDIA_BKP)
			SET @DIR_ARQ_DADOS = (SELECT @DIR_BANCO + @ARQ_LOGICO_DATA + '.mdf')
			SET @DIR_ARQ_LOG = (SELECT @DIR_BANCO + @ARQ_LOGICO_LOG + '.ldf')

			--Carrega a variável com o script de restauração do banco de dados
			SET @SQL_STATEMENT_RESTORE = N'USE [master]
										ALTER DATABASE '+@BD_CLIENTE+'
											SET SINGLE_USER 
											WITH ROLLBACK IMMEDIATE
										RESTORE DATABASE '+@BD_CLIENTE+'
										FROM  DISK = N'''+@DIR_MIDIA_BACKUP+'''
										WITH  FILE = 1,  
										MOVE N'''+@ARQ_LOGICO_DATA+''' 
											TO N'''+@DIR_ARQ_DADOS+''',  
										MOVE N'''+@ARQ_LOGICO_LOG+''' 
											TO N'''+@DIR_ARQ_LOG+''',  
										NOUNLOAD,  
										REPLACE,  
										STATS = 1
										ALTER DATABASE '+@BD_CLIENTE+'
										SET MULTI_USER'
	

			--Carrega a variável com o script de criação do banco de dados
			SET @SQL_STATEMENT_CREATE_DB = N'USE [master]
											BEGIN
												CREATE DATABASE '+@BD_CLIENTE+'
												 CONTAINMENT = NONE
												 ON  PRIMARY 
												( NAME = N'''+@ARQ_LOGICO_DATA+''', FILENAME = N'''+@DIR_ARQ_DADOS+''' , SIZE = 8192KB , FILEGROWTH = 65536KB )
												 LOG ON 
												( NAME = N'''+@ARQ_LOGICO_LOG+''', FILENAME = N'''+@DIR_ARQ_LOG+''' , SIZE = 8192KB , FILEGROWTH = 65536KB )
											END
									
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET COMPATIBILITY_LEVEL = 150
											END
									
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET ANSI_NULL_DEFAULT OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET ANSI_NULLS OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET ANSI_PADDING OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET ANSI_WARNINGS OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET ARITHABORT OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET AUTO_CLOSE OFF 
											END 
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET AUTO_SHRINK OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET AUTO_UPDATE_STATISTICS ON 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET CURSOR_CLOSE_ON_COMMIT OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET CURSOR_DEFAULT  GLOBAL 
											END 
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET CONCAT_NULL_YIELDS_NULL OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET NUMERIC_ROUNDABORT OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET QUOTED_IDENTIFIER OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET RECURSIVE_TRIGGERS OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET  DISABLE_BROKER 
											END 
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET DATE_CORRELATION_OPTIMIZATION OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET PARAMETERIZATION SIMPLE 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET READ_COMMITTED_SNAPSHOT OFF 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET  READ_WRITE 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET RECOVERY FULL 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET  MULTI_USER 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET PAGE_VERIFY CHECKSUM  
											END 
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET TARGET_RECOVERY_TIME = 60 SECONDS 
											END
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' SET DELAYED_DURABILITY = DISABLED 
											END'


			--Carrega o restante do script de criação. 
			--Teve de ser divido em 2 partes devido a uma limitação do sp_executesql que nao conseguia alternar do [master] para o banco criado					
			SET @SQL_STATEMENT_CREATE_DB_CONT =	N'USE '+@BD_CLIENTE+'
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
											END
											BEGIN
												ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
											END

											IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N''PRIMARY'') 
											BEGIN
												ALTER DATABASE '+@BD_CLIENTE+' 
												MODIFY FILEGROUP [PRIMARY] DEFAULT
											END'


			----se o banco de dados a ser restaurado existir, inicia o procedimento de restore
			IF EXISTS (SELECT 1 FROM sys.databases WHERE [NAME] = @BD_CLIENTE_SEM_COLCHETE)
			BEGIN
				PRINT 'Banco de Dados encontrado, iniciando o procedimento de restauração'		
				PRINT 'Iniciando o procedimento de restauração.'

				BEGIN
					EXEC SP_EXECUTESQL @SQL_STATEMENT_RESTORE
				END

				PRINT 'Banco de dados restaurado com sucesso!'
		
				PRINT 'Registrando Log do backup restaurado...'
		
				BEGIN
					EXEC [MASTER].DBO.sp_Cria_Registro_Backup @TIPO_BANCO, @DATA_MIDIA_BACKUP, @SIGLA_CLIENTE, @OBSERVACOES
				END
		
				 PRINT 'Procedimento Finalizado!!!'
			END


			--se o banco de dados a ser restaurado não existir, cria um novo banco e inicia o processo de restauração na sequencia
			IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE [NAME] = @BD_CLIENTE_SEM_COLCHETE)
			BEGIN
				PRINT 'Banco de dados não encontrado, Criando o banco '+@BD_CLIENTE+''

				BEGIN
					EXEC SP_EXECUTESQL @SQL_STATEMENT_CREATE_DB
					EXEC SP_EXECUTESQL @SQL_STATEMENT_CREATE_DB_CONT
				END

				PRINT 'Banco de Dados criado com sucesso!'
				PRINT 'Iniciando o procedimento de restauração.'
		
				BEGIN			
					EXEC SP_EXECUTESQL @SQL_STATEMENT_RESTORE
				END

				PRINT 'Banco de dados restaurado com sucesso!'
				PRINT 'Registrando Log do backup restaurado...'

				BEGIN	
					EXEC [MASTER].DBO.sp_Cria_Registro_Backup @TIPO_BANCO, @DATA_MIDIA_BACKUP, @SIGLA_CLIENTE, @OBSERVACOES
				END

				PRINT 'Procedimento Finalizado!!!'
			END   
	
		Set NoCount Off;
	End
Go

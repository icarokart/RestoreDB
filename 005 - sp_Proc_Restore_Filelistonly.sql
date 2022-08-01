/*
-----------------------------------------------------------------------
Data de Criação: 01/08/2022
Nome do Objeto: sp_Proc_Restore_Filelistonly
Autor: Ícaro
----------------------------------------------------------------------
*/

If Exists (Select 1 From Sysobjects Where Id = Object_Id('dbo.[sp_Proc_Restore_Filelistonly]'))
     Drop Procedure dbo.sp_Proc_Restore_Filelistonly
Go

Create Procedure dbo.sp_Proc_Restore_Filelistonly
(
	@Caminho_Midia nvarchar(360)
) As
Begin
     Set NoCount On;
     
		RESTORE FILELISTONLY FROM DISK = @Caminho_Midia
      
     Set NoCount Off;
End
Go

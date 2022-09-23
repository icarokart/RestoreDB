/*
-----------------------------------------------------------------------
Data de Cria��o: 04/09/2022
Nome do Objeto: sp_Proc_Restore_Headeronly
Autor: �caro

Altera��es:
		[�caro - 04/09/2022] => Procedimento movido para um BD pr�prio
----------------------------------------------------------------------
*/

If Exists (Select 1 From Sysobjects Where Id = Object_Id('dbo.[sp_Proc_Restore_Headeronly]'))
     Drop Procedure dbo.sp_Proc_Restore_Headeronly
Go

Create Procedure dbo.sp_Proc_Restore_Headeronly
(
	@Caminho_Midia nvarchar(360) 
) As
Begin
     Set NoCount On;
     
		RESTORE HEADERONLY FROM DISK = @Caminho_Midia

     Set NoCount Off;
End
Go
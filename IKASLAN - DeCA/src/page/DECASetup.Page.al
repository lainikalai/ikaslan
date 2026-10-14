page 50000 "DECA Setup"
{
    Caption = 'Configuración DeCA';
    PageType = Card;
    SourceTable = "DECA Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Company Role"; Rec."Company Role")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cargador contractual: la empresa envía mercancía con transportistas contratados. Transportista efectivo: la empresa realiza el transporte para sus clientes.';
                }
                field("DeCA Nos."; Rec."DeCA Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Serie numérica de los DeCA.';
                }
                field("Default Goods Description"; Rec."Default Goods Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Si se indica, se usa como naturaleza de la mercancía. Si se deja vacío, se compone con las descripciones de las líneas del documento.';
                }
                field("Default Service Duration"; Rec."Default Service Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Días que se suman a la fecha del transporte para proponer la fecha fin del servicio.';
                }
                field("Days Online After Service"; Rec."Days Online After Service")
                {
                    ApplicationArea = All;
                    ToolTip = 'Días naturales tras el fin del servicio durante los que la URL sigue descargando el PDF. Mínimo 7.';
                }
            }
            group(Repository)
            {
                Caption = 'Repositorio';

                field("Storage Provider"; Rec."Storage Provider")
                {
                    ApplicationArea = All;
                    ToolTip = 'Repositorio externo donde se publican los PDF.';
                }
                field("Storage Account Name"; Rec."Storage Account Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la cuenta de Azure Storage.';
                }
                field("Container Name"; Rec."Container Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Contenedor donde se guardan los PDF.';
                }
                field(StorageAccountKey; StorageAccountKeyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Clave de la cuenta';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Clave de acceso de la cuenta de almacenamiento. Se guarda cifrada y solo se usa para subir y retirar ficheros.';

                    trigger OnValidate()
                    begin
                        Rec.SetStorageAccountKey(StorageAccountKeyTxt);
                        SetKeyPlaceholder();
                    end;
                }
                field("Read SAS Token"; Rec."Read SAS Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Token SAS de solo lectura que se añade a la URL. Déjelo vacío si el contenedor tiene acceso anónimo de lectura a nivel de blob.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DisableExpiredUrls)
            {
                ApplicationArea = All;
                Caption = 'Desactivar descargas caducadas';
                Image = Process;
                ToolTip = 'Retira del repositorio los PDF cuyo servicio terminó hace más días de los configurados. Lo mismo hace el codeunit 50020 desde la cola de proyectos.';

                trigger OnAction()
                var
                    DECAJobQueue: Codeunit "DECA Job Queue";
                    DoneMsg: Label 'Descargas desactivadas: %1.', Comment = '%1 = número';
                begin
                    Message(DoneMsg, DECAJobQueue.DisableExpiredUrls());
                end;
            }
        }
    }

    var
        StorageAccountKeyTxt: Text;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        SetKeyPlaceholder();
    end;

    local procedure SetKeyPlaceholder()
    begin
        if Rec.HasStorageAccountKey() then
            StorageAccountKeyTxt := '**********'
        else
            StorageAccountKeyTxt := '';
    end;
}

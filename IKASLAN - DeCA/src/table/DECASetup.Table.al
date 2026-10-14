table 50000 "DECA Setup"
{
    Caption = 'Configuración DeCA';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(2; "Company Role"; Enum "DECA Company Role")
        {
            Caption = 'Rol de la empresa';
        }
        field(3; "DeCA Nos."; Code[20])
        {
            Caption = 'Nº serie DeCA';
            TableRelation = "No. Series";
        }
        field(4; "Default Goods Description"; Text[100])
        {
            Caption = 'Naturaleza de la mercancía por defecto';
        }
        field(5; "Default Service Duration"; Integer)
        {
            Caption = 'Duración del servicio por defecto (días)';
            MinValue = 0;
        }
        field(6; "Days Online After Service"; Integer)
        {
            Caption = 'Días de descarga tras el servicio';
            InitValue = 7;

            trigger OnValidate()
            begin
                // Resolución 5/6/2026, apartado tercero.5: mínimo siete días naturales
                if "Days Online After Service" < 7 then
                    Error(MinDaysErr);
            end;
        }
        field(10; "Storage Provider"; Enum "DECA Storage Provider")
        {
            Caption = 'Repositorio';
        }
        field(11; "Storage Account Name"; Text[50])
        {
            Caption = 'Cuenta de almacenamiento';
        }
        field(12; "Container Name"; Text[63])
        {
            Caption = 'Contenedor';
        }
        field(13; "Read SAS Token"; Text[1024])
        {
            Caption = 'Token SAS de lectura (opcional)';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    var
        MinDaysErr: Label 'La descarga debe seguir activa al menos 7 días naturales tras finalizar el servicio.';
        NoKeyErr: Label 'No se ha indicado la clave de la cuenta de almacenamiento en la configuración DeCA.';
        StorageKeyTok: Label 'DECA-StorageAccountKey', Locked = true;

    procedure GetSetup()
    var
        NoSetupErr: Label 'Falta la configuración DeCA. Abra la página "Configuración DeCA".';
    begin
        if not Get() then
            Error(NoSetupErr);
    end;

    procedure SetStorageAccountKey(NewKey: SecretText)
    begin
        if NewKey.IsEmpty() then begin
            if IsolatedStorage.Contains(StorageKeyTok, DataScope::Company) then
                IsolatedStorage.Delete(StorageKeyTok, DataScope::Company);
            exit;
        end;
        IsolatedStorage.Set(StorageKeyTok, NewKey, DataScope::Company);
    end;

    procedure GetStorageAccountKey(): SecretText
    var
        StorageKey: SecretText;
    begin
        if not IsolatedStorage.Get(StorageKeyTok, DataScope::Company, StorageKey) then
            Error(NoKeyErr);
        exit(StorageKey);
    end;

    procedure HasStorageAccountKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(StorageKeyTok, DataScope::Company));
    end;
}

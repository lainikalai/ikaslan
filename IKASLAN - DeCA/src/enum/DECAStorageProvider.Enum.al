enum 50030 "DECA Storage Provider" implements "DECA Document Storage"
{
    Extensible = true;
    Caption = 'Repositorio DeCA';

    value(0; "Azure Blob Storage")
    {
        Caption = 'Azure Blob Storage';
        Implementation = "DECA Document Storage" = "DECA Azure Blob Storage";
    }
}

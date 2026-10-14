permissionset 50000 "DECA - Edit"
{
    Assignable = true;
    Caption = 'DeCA - Emisión';
    Permissions =
        tabledata "DECA Setup" = R,
        tabledata "DECA Header" = RIMD,
        tabledata "DECA Line" = RIMD,
        table "DECA Setup" = X,
        table "DECA Header" = X,
        table "DECA Line" = X,
        codeunit "DECA Management" = X,
        codeunit "DECA Azure Blob Storage" = X,
        codeunit "DECA Job Queue" = X,
        page "DECA List" = X,
        page "DECA Card" = X,
        page "DECA Subform" = X,
        report "DECA Document" = X;
}

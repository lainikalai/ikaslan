permissionset 50010 "DECA - Admin"
{
    Assignable = true;
    Caption = 'DeCA - Administración';
    IncludedPermissionSets = "DECA - Edit";
    Permissions =
        tabledata "DECA Setup" = RIMD,
        page "DECA Setup" = X;
}

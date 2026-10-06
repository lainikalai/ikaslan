enum 99111 "IKA DN Source"
{
    Caption = 'Origen albarán';
    Extensible = true;

    value(0; Manual)
    {
        Caption = 'Manual';
    }
    value(10; Email)
    {
        Caption = 'Email (Outlook)';
    }
    value(20; Folder)
    {
        Caption = 'Carpeta (SharePoint/OneDrive)';
    }
}

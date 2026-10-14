page 99251 "IKA Mail Address Filter"
{
    // Diálogo para cambiar los filtros del FactBox "Emails enviados y recibidos".
    Caption = 'Filtrar emails';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(AddressFilterText; AddressFilterText)
            {
                ApplicationArea = All;
                Caption = 'Email';
                ExtendedDatatype = EMail;
                ToolTip = 'Dirección (o varias separadas por ;) con la que se han enviado o recibido los emails. Con @dominio.com se busca todo el dominio.';
            }
            field(SubjectFilterText; SubjectFilterText)
            {
                ApplicationArea = All;
                Caption = 'Asunto';
                ToolTip = 'Palabras que debe contener el asunto (todas). Admite * al final de una palabra, p.ej. pedi*.';
            }
        }
    }

    var
        AddressFilterText: Text;
        SubjectFilterText: Text;

    procedure SetFilters(NewAddressFilter: Text; NewSubjectFilter: Text)
    begin
        AddressFilterText := NewAddressFilter;
        SubjectFilterText := NewSubjectFilter;
    end;

    procedure GetFilters(var NewAddressFilter: Text; var NewSubjectFilter: Text)
    begin
        NewAddressFilter := AddressFilterText;
        NewSubjectFilter := SubjectFilterText;
    end;
}

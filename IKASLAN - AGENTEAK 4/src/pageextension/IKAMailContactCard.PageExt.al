pageextension 50402 "IKA Mail Contact Card" extends "Contact Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Contact), "Entity No." = field("No.");
            }
            // Esta ficha no trae el FactBox de adjuntos estándar en todas las versiones.
            // Si al compilar o en pantalla aparece duplicado, borre esta parte.
            part("IKA Attached Documents"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documentos adjuntos';
                SubPageLink = "Table ID" = const(5050), "No." = field("No.");
            }
        }
    }
}

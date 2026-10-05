page 50670 "IKA WA Secret Input"
{
    Caption = 'Introducir clave';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(SecretValue; SecretValue)
            {
                ApplicationArea = All;
                Caption = 'Valor';
                ExtendedDatatype = Masked;
                ToolTip = 'El valor se guarda cifrado y no se puede volver a mostrar. Deje vacío para borrarlo.';
            }
        }
    }

    var
        [NonDebuggable]
        SecretValue: Text;

    [NonDebuggable]
    procedure GetSecret(): Text
    begin
        exit(SecretValue);
    end;
}

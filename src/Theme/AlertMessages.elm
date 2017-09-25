module Theme.AlertMessages exposing (..)

import ClientTypes exposing (..)
import TranslationHelper exposing ( getInLanguage )

import Html exposing (div , span , br, text , Html )
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


viewAlertMessages : List String -> String  ->Html ClientTypes.Msg
viewAlertMessages lAlertMessages lgId =
    if ( List.length lAlertMessages ) /= 0  then
         div [ class "alert" ]
                <| ( ( lAlertMessages
                       |> List.map (\x -> text <| getInLanguage lgId x )
                       |> List.intersperse (br[][])
                      )
                     ++
                     [ span [ class "close" , onClick CloseAlert ] [text "X"] ]
                   )
    else
        text ""

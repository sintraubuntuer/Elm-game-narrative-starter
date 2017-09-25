module Theme.Inventory exposing (..)

import Html exposing (..)
import Html.Keyed
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)
import Components exposing (..)
import Tuple
import TranslationHelper exposing (getInLanguage)


view :
    List Entity
    -> String
    -> Bool
    -> Html Msg
view items lgId bWithSidebar =
    let
        numItems =
            List.length items

        inventoryItemClasses =
            if bWithSidebar then
                "Inventory__Item u-selectable"
            else
                "Inventory__Item__NoSidebar u-selectable"

        elem =
            if (bWithSidebar) then
                li
            else
                span

        inventoryItem i entity =
            let
                key =
                    (toString <| Tuple.first entity) ++ (toString <| numItems - i)
            in
                ( key
                , elem
                    [ class inventoryItemClasses
                    , onClick <| Interact <| Tuple.first entity
                    ]
                    [ text <| .name <| getSingleLgDisplayInfo lgId entity ]
                )

        inventoryClass =
            if bWithSidebar then
                "Inventory"
            else
                "Inventory__NoSidebar"
    in
        div [ class inventoryClass ]
            [ if (bWithSidebar) then
                h3 [] [ text <| getInLanguage lgId "__Inventory__" ]
              else
                text ""
            , div [ class "Inventory__list" ]
                [ if (bWithSidebar) then
                    Html.Keyed.ol []
                        (List.indexedMap inventoryItem items)
                  else
                    List.indexedMap inventoryItem items
                        |> List.map Tuple.second
                        |> List.intersperse (text " , ")
                        |> (::) (text <| (getInLanguage lgId "__Inventory__" ++ " : "))
                        |> p []
                ]
            ]

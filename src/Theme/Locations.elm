module Theme.Locations exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)
import Components exposing (..)
import Tuple
import TranslationHelper exposing (getInLanguage)


view :
    List ( Direction, Entity )
    -> Entity
    -> String
    -> Bool
    -> Html Msg
view exits currentLocation lgId bWithSidebar =
    let
        interactableView msg entity direction =
            span []
                [ span
                    [ class "CurrentSummary__StoryElement u-selectable"
                    , onClick <| msg <| Tuple.first entity
                    ]
                    [ text <|
                        (.name <| getSingleLgDisplayInfo lgId entity)
                    ]
                , text (" is to the " ++ toString direction)
                ]

        formatIt bWithSidebar list =
            let
                interactables =
                    if (bWithSidebar) then
                        List.intersperse (br [] []) list
                    else
                        List.intersperse (text ", ") list
            in
                if (bWithSidebar) then
                    interactables
                        |> p []
                else
                    interactables
                        ++ [ text "." ]
                        |> (::) (text <| getInLanguage lgId "Connecting locations : ")
                        |> p []

        theExitsList =
            if not <| List.isEmpty exits then
                exits
                    |> List.map (\( direction, entity ) -> interactableView Interact entity direction)
                    |> formatIt bWithSidebar
                --|> if ( bWithSidebar ) then p[] else (formatToSpan bWithSidebar)
            else
                span [] []

        locationsClass =
            if bWithSidebar then
                "Locations"
            else
                "Locations__NoSidebar"
    in
        div [ class locationsClass ]
            [ if (bWithSidebar) then
                h3 [] [ text "Connecting locations" ]
              else
                text ""
            , div [ class "Locations__list" ]
                [ {- }
                     if ( not bWithSidebar ) then
                         text "Connecting locations"
                     else
                         text ""
                  -}
                  theExitsList
                ]
            ]
